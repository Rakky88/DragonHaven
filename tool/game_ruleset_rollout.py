"""Controlled DragonHaven game-worker rollout with automatic rollback.

The helper deliberately keeps schema application separate. It will only roll a
worker when local and remote migration histories already match exactly. It
stores the previous Edge Function source and the non-secret runtime row before
changing anything, then restores both if deployment, activation, the
synthetic authenticated smoke check, or mandatory server postflight fails.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid


PROJECTS = {
    "staging": "vtmjkhzalalozpfnbvsd",
    "production": "tnzathhutuwmohmjfrlo",
}
FUNCTION = "execute-game-command"
HASH = re.compile(r"^[0-9a-f]{64}$")
BUILD = re.compile(r"^[1-9][0-9]{0,9}$")
TAG = re.compile(r"^v[0-9]+\.[0-9]+\.[0-9]+$")
SEMANTIC_VERSION = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
RUNTIME_FIELDS = (
    "enabled",
    "migration_enabled",
    "minimum_client_build",
    "ruleset_sha256",
    "shadow_social_enabled",
    "shadow_projection_enabled",
    "shadow_lifecycle_enabled",
)


class RolloutError(RuntimeError):
    """Sanitized operator-facing failure."""


def _semantic_version(value: str) -> tuple[int, int, int] | None:
    if SEMANTIC_VERSION.fullmatch(value) is None:
        return None
    major, minor, patch = value.split(".")
    return int(major), int(minor), int(patch)


def _json_from_output(output: str) -> object:
    decoder = json.JSONDecoder()
    for index, character in enumerate(output):
        if character not in "[{":
            continue
        try:
            value, end = decoder.raw_decode(output[index:])
        except json.JSONDecodeError:
            continue
        if not output[index + end :].strip():
            return value
    raise RolloutError("command_json_invalid")


def _sql(value: object) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, str):
        return "'" + value.replace("'", "''") + "'"
    raise RolloutError("unsafe_sql_value")


def _ruleset_from(directory: Path) -> str:
    bridge = directory / "supabase/functions/execute-game-command/bundle.generated.ts"
    bundle = directory / "supabase/functions/execute-game-command/game.generated.js"
    if not bridge.is_file() or not bundle.is_file():
        raise RolloutError("generated_worker_missing")
    match = re.search(r"export const ruleset = '([0-9a-f]{64})';", bridge.read_text("utf-8"))
    if match is None:
        raise RolloutError("generated_ruleset_missing")
    actual = hashlib.sha256(bundle.read_bytes()).hexdigest()
    if actual != match.group(1):
        raise RolloutError("generated_ruleset_hash_mismatch")
    return actual


def _local_versions(root: Path) -> list[str]:
    versions: list[str] = []
    for path in sorted((root / "supabase/migrations").glob("*.sql")):
        match = re.match(r"^(\d+)_", path.name)
        if match is None:
            raise RolloutError("local_migration_name_invalid")
        versions.append(match.group(1))
    if not versions or len(versions) != len(set(versions)):
        raise RolloutError("local_migration_history_invalid")
    return versions


def _safe_runtime(value: object) -> dict[str, object]:
    if not isinstance(value, dict):
        raise RolloutError("runtime_invalid")
    required = {*RUNTIME_FIELDS, "ruleset_revision", "updated_at", "singleton"}
    if not required.issubset(value):
        raise RolloutError("runtime_contract_incomplete")
    runtime = {key: value[key] for key in sorted(required)}
    if runtime["singleton"] is not True:
        raise RolloutError("runtime_singleton_invalid")
    for key in RUNTIME_FIELDS:
        if key.endswith("enabled") and not isinstance(runtime[key], bool):
            raise RolloutError("runtime_switch_invalid")
    if not isinstance(runtime["minimum_client_build"], int) or runtime["minimum_client_build"] < 1:
        raise RolloutError("runtime_build_invalid")
    ruleset = runtime["ruleset_sha256"]
    if ruleset is not None and (not isinstance(ruleset, str) or HASH.fullmatch(ruleset) is None):
        raise RolloutError("runtime_ruleset_invalid")
    if not isinstance(runtime["ruleset_revision"], int) or runtime["ruleset_revision"] < 1:
        raise RolloutError("runtime_revision_invalid")
    if not isinstance(runtime["updated_at"], str) or not runtime["updated_at"]:
        raise RolloutError("runtime_timestamp_invalid")
    return runtime


class Rollout:
    def __init__(self, args: argparse.Namespace) -> None:
        self.args = args
        self.root = Path(__file__).resolve().parent.parent
        self.project = PROJECTS[args.environment]
        self.base = f"https://{self.project}.supabase.co"
        self.evidence = Path(args.evidence_dir).resolve()
        self.token = os.environ.get("SUPABASE_ACCESS_TOKEN", "").strip()
        self.baseline_runtime: dict[str, object] | None = None
        self.baseline_function: dict[str, object] | None = None
        self.candidate_runtime: dict[str, object] | None = None
        self.candidate_function: dict[str, object] | None = None
        self.new_ruleset = ""
        self.worker_deploy_attempted = False

    def _run(self, command: list[str], label: str, cwd: Path | None = None) -> str:
        completed = subprocess.run(
            command,
            cwd=str(cwd or self.root),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            encoding="utf-8",
            errors="replace",
        )
        if completed.returncode != 0:
            raise RolloutError(label)
        print(f"PASS: {label}", flush=True)
        return completed.stdout

    def _request(
        self,
        url: str,
        *,
        headers: dict[str, str] | None = None,
        data: object | None = None,
        method: str | None = None,
        label: str,
        expected: tuple[int, ...] = (200,),
    ) -> object:
        body = None if data is None else json.dumps(data, separators=(",", ":")).encode()
        request = urllib.request.Request(
            url,
            data=body,
            method=method,
            headers={"Content-Type": "application/json", "User-Agent": "DragonHaven-Ruleset-Rollout/1", **(headers or {})},
        )
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                raw = response.read()
                status = response.status
        except urllib.error.HTTPError as error:
            status = error.code
            raw = b""
        except (OSError, TimeoutError):
            raise RolloutError(label + "_unavailable") from None
        if status not in expected:
            raise RolloutError(label + f"_http_{status}")
        if not raw:
            return None
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            raise RolloutError(label + "_json_invalid") from None

    def _management(self, path: str, *, data: object | None = None, label: str) -> object:
        if not self.token:
            raise RolloutError("supabase_access_token_missing")
        return self._request(
            "https://api.supabase.com/v1/projects/" + self.project + path,
            headers={"Authorization": "Bearer " + self.token},
            data=data,
            label=label,
            expected=(200, 201),
        )

    def _query(self, sql: str, label: str, *, read_only: bool = False) -> list[dict[str, object]]:
        result = self._management(
            "/database/query",
            data={"query": sql, "read_only": read_only},
            label=label,
        )
        if not isinstance(result, list) or any(not isinstance(row, dict) for row in result):
            raise RolloutError(label + "_result_invalid")
        return result

    def _runtime(self) -> dict[str, object]:
        rows = self._query(
            "select to_jsonb(r) as runtime from private.game_engine_runtime r where singleton",
            "runtime_read",
            read_only=True,
        )
        if len(rows) != 1:
            raise RolloutError("runtime_row_invalid")
        return _safe_runtime(rows[0].get("runtime"))

    def _function(self) -> dict[str, object]:
        result = self._management("/functions", label="function_metadata")
        if not isinstance(result, list):
            raise RolloutError("function_metadata_invalid")
        matches = [item for item in result if isinstance(item, dict) and item.get("slug") == FUNCTION]
        if len(matches) != 1:
            raise RolloutError("function_metadata_missing")
        item = matches[0]
        if (
            item.get("status") != "ACTIVE"
            or item.get("verify_jwt") is not False
            or not isinstance(item.get("version"), int)
            or not isinstance(item.get("ezbr_sha256"), str)
            or HASH.fullmatch(str(item["ezbr_sha256"])) is None
        ):
            raise RolloutError("function_metadata_unsafe")
        return {
            "slug": FUNCTION,
            "status": item["status"],
            "verify_jwt": item["verify_jwt"],
            "version": item["version"],
            "ezbr_sha256": item["ezbr_sha256"],
        }

    def _write(self, name: str, value: object) -> None:
        path = self.evidence / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", "utf-8")

    def _download(self, destination: Path, label: str) -> str:
        destination.mkdir(parents=True, exist_ok=False)
        self._run(
            [
                self.args.supabase,
                "functions",
                "download",
                FUNCTION,
                "--project-ref",
                self.project,
                "--use-api",
                "--workdir",
                str(destination),
            ],
            label,
        )
        return _ruleset_from(destination)

    def _deploy(self, source: Path, label: str) -> None:
        self._run(
            [
                self.args.supabase,
                "functions",
                "deploy",
                FUNCTION,
                "--project-ref",
                self.project,
                "--no-verify-jwt",
                "--use-api",
                "--workdir",
                str(source),
            ],
            label,
        )

    def _update_runtime(
        self,
        expected: dict[str, object],
        changes: dict[str, object],
        label: str,
    ) -> dict[str, object]:
        predicates = ["r.singleton"]
        for key in (*RUNTIME_FIELDS, "updated_at"):
            value = expected[key]
            predicates.append(f"r.{key} is not distinct from {_sql(value)}")
        assignments = ",".join(f"{key}={_sql(value)}" for key, value in changes.items())
        sql = (
            "with changed as (update private.game_engine_runtime as r set "
            + assignments
            + " where "
            + " and ".join(predicates)
            + " returning to_jsonb(r) as runtime) select runtime from changed"
        )
        rows = self._query(sql, label)
        if len(rows) != 1:
            raise RolloutError(label + "_concurrent_change")
        return _safe_runtime(rows[0].get("runtime"))

    @staticmethod
    def _same_runtime_state(
        actual: dict[str, object],
        expected: dict[str, object],
    ) -> bool:
        return all(
            actual[key] == expected[key]
            for key in (*RUNTIME_FIELDS, "ruleset_revision", "singleton")
        )

    @staticmethod
    def _same_function_state(
        actual: dict[str, object],
        expected: dict[str, object],
    ) -> bool:
        return all(
            actual[key] == expected[key]
            for key in ("slug", "status", "verify_jwt", "version", "ezbr_sha256")
        )

    def _owned_runtime_states(self) -> list[dict[str, object]]:
        if self.baseline_runtime is None:
            return []
        baseline = dict(self.baseline_runtime)
        paused = dict(baseline, enabled=False, migration_enabled=False)
        candidate = dict(
            baseline,
            minimum_client_build=self.args.minimum_client_build,
            ruleset_sha256=self.new_ruleset,
            ruleset_revision=baseline["ruleset_revision"] + 1,
        )
        transient = dict(candidate, enabled=True, migration_enabled=True)
        states = [baseline, paused, candidate, transient]
        if self.candidate_runtime is not None:
            states.append(self.candidate_runtime)
        return states

    def _verify_staging_dormant(self, label: str) -> None:
        counts = self._query(
            "select count(*)::int as accounts from private.canonical_game_states",
            label,
            read_only=True,
        )
        if self.args.environment != "staging" or counts != [{"accounts": 0}]:
            raise RolloutError("dormant_smoke_not_isolated")

    def _verify_migrations_and_lint(self) -> None:
        output = self._run(
            [
                self.args.supabase,
                "migration",
                "list",
                "--project-ref",
                self.project,
                "--output-format",
                "json",
            ],
            "migration_history_read",
        )
        parsed = _json_from_output(output)
        if not isinstance(parsed, dict) or not isinstance(parsed.get("migrations"), list):
            raise RolloutError("remote_migration_history_invalid")
        remote = [str(item.get("remote")) for item in parsed["migrations"] if item.get("remote")]
        local = _local_versions(self.root)
        if remote != local:
            raise RolloutError("migration_history_not_exact")
        self._run(
            [
                self.args.supabase,
                "db",
                "lint",
                "--linked",
                "--project-ref",
                self.project,
                "--level",
                "error",
                "--fail-on",
                "error",
                "--output-format",
                "json",
            ],
            "database_lint",
        )

    def _build_and_test(self) -> None:
        self._run([self.args.dart, "run", "tool/build_server_game.dart"], "worker_build")
        self.new_ruleset = _ruleset_from(self.root)
        self._run(
            [self.args.deno, "check", "supabase/functions/execute-game-command/index.ts"],
            "worker_typecheck",
        )
        self._run(
            [self.args.deno, "test", "supabase/functions/execute-game-command/"],
            "worker_tests",
        )

    def _verify_release(self) -> None:
        if self.args.environment != "production" or self.args.mode != "apply":
            return
        if TAG.fullmatch(self.args.release_tag or "") is None:
            raise RolloutError("release_tag_required")
        if HASH.fullmatch(self.args.apk_sha256 or "") is None:
            raise RolloutError("release_apk_sha256_required")
        pubspec = (self.root / "pubspec.yaml").read_text("utf-8")
        match = re.search(r"^version:\s*([^+\s]+)\+([0-9]+)\s*$", pubspec, re.MULTILINE)
        source_version = None if match is None else _semantic_version(match.group(1))
        release_version = _semantic_version((self.args.release_tag or "")[1:])
        if source_version is None or source_version != release_version:
            raise RolloutError("release_source_version_mismatch")
        if int(match.group(2)) != self.args.minimum_client_build:
            raise RolloutError("release_source_build_mismatch")
        tag_commit = self._run(
            ["git", "rev-list", "-n", "1", self.args.release_tag],
            "release_tag_resolve",
        ).strip()
        head = self._run(["git", "rev-parse", "HEAD"], "release_head_resolve").strip()
        if not re.fullmatch(r"[0-9a-f]{40}", tag_commit) or tag_commit != head:
            raise RolloutError("release_tag_not_exact_source")
        tag = urllib.parse.quote(self.args.release_tag, safe="")
        release = self._request(
            f"https://api.github.com/repos/{self.args.github_repository}/releases/tags/{tag}",
            label="release_lookup",
        )
        latest = self._request(
            f"https://api.github.com/repos/{self.args.github_repository}/releases/latest",
            label="latest_release_lookup",
        )
        if not isinstance(release, dict) or not isinstance(latest, dict):
            raise RolloutError("release_response_invalid")
        assets = release.get("assets")
        asset = next(
            (item for item in assets if isinstance(item, dict) and item.get("name") == "DragonHaven.apk"),
            None,
        ) if isinstance(assets, list) else None
        if (
            release.get("tag_name") != self.args.release_tag
            or release.get("draft") is not False
            or release.get("prerelease") is not False
            or latest.get("tag_name") != self.args.release_tag
            or not isinstance(asset, dict)
            or asset.get("digest") != "sha256:" + self.args.apk_sha256
            or not isinstance(asset.get("size"), int)
            or asset["size"] < 1
        ):
            raise RolloutError("public_release_not_verified")

    def _postflight(self) -> None:
        command = [
            self.args.pwsh,
            "-NoLogo",
            "-NoProfile",
            "-File",
            str(self.root / "tool/release_server_preflight.ps1"),
            "-SupabaseCli",
            self.args.supabase,
            "-ExpectedProjectRef",
            self.project,
        ]
        if self.args.environment == "staging":
            command.extend(
                [
                    "-ExpectedUrl",
                    self.args.expected_url,
                    "-ExpectedPublishableKey",
                    self.args.expected_publishable_key,
                ]
            )
        output = self._run(command, "server_postflight")
        (self.evidence / "server-postflight.txt").write_text(output, "utf-8")

    def _smoke_http(
        self,
        path: str,
        headers: dict[str, str],
        payload: object | None,
        label: str,
        expected: tuple[int, ...] = (200,),
        method: str | None = None,
    ) -> object:
        return self._request(
            self.base + path,
            headers=headers,
            data=payload,
            method=method,
            label="smoke_" + label,
            expected=expected,
        )

    def _cleanup_synthetic(self, run: str, owner: str | None) -> None:
        deleted = self._query(
            "delete from auth.users where raw_app_meta_data->>'dragonhaven_ruleset_rollout'="
            + _sql(run)
            + " and email like '%@dragonhaven-ruleset.invalid' returning id::text as id",
            "smoke_cleanup_delete",
        )
        if len(deleted) > 1:
            raise RolloutError("smoke_cleanup_scope_invalid")
        owners = {owner} if owner is not None else set()
        for row in deleted:
            value = row.get("id")
            try:
                owners.add(str(uuid.UUID(str(value))))
            except (ValueError, TypeError, AttributeError):
                raise RolloutError("smoke_cleanup_owner_invalid") from None
        marker = self._query(
            "select count(*)::int as users from auth.users where "
            "raw_app_meta_data->>'dragonhaven_ruleset_rollout'="
            + _sql(run),
            "smoke_cleanup_marker_verify",
            read_only=True,
        )
        if marker != [{"users": 0}]:
            raise RolloutError("smoke_cleanup_marker_retained")
        if not owners:
            return
        owner_list = ",".join(_sql(value) + "::uuid" for value in sorted(owners))
        rows = self._query(
            "select (select count(*)::int from auth.users where id in ("
            + owner_list
            + ")) as users,(select count(*)::int from private.canonical_game_states where owner_id in ("
            + owner_list
            + ")) as games",
            "smoke_cleanup_verify",
            read_only=True,
        )
        if rows != [{"users": 0, "games": 0}]:
            raise RolloutError("smoke_cleanup_incomplete")

    def _smoke(self, candidate_runtime: dict[str, object]) -> dict[str, object]:
        transient = not bool(candidate_runtime["enabled"]) or not bool(candidate_runtime["migration_enabled"])
        run = uuid.uuid4().hex
        owner: str | None = None
        transient_enabled = False
        cleanup_failure: Exception | None = None
        restore_failure: Exception | None = None
        transient_runtime: dict[str, object] | None = None
        try:
            if transient:
                self._verify_staging_dormant("staging_account_count")
                transient_runtime = self._update_runtime(
                    candidate_runtime,
                    {"enabled": True, "migration_enabled": True},
                    "smoke_runtime_enable",
                )
                transient_enabled = True
            keys = self._management("/api-keys?reveal=true", label="smoke_keys")
            if not isinstance(keys, list):
                raise RolloutError("smoke_keys_invalid")
            try:
                service_key = next(item["api_key"] for item in keys if item.get("name") == "service_role")
                public_key = next(item["api_key"] for item in keys if item.get("name") == "anon")
            except (StopIteration, KeyError, TypeError):
                raise RolloutError("smoke_keys_missing") from None
            email = run + "@dragonhaven-ruleset.invalid"
            password = secrets.token_urlsafe(36) + "Dh7!"
            admin = {"apikey": service_key, "Authorization": "Bearer " + service_key}
            user = self._smoke_http(
                "/auth/v1/admin/users",
                admin,
                {
                    "email": email,
                    "password": password,
                    "email_confirm": True,
                    "app_metadata": {"dragonhaven_ruleset_rollout": run},
                },
                "user_create",
                expected=(200, 201),
            )
            if not isinstance(user, dict) or not isinstance(user.get("id"), str):
                raise RolloutError("smoke_user_invalid")
            owner = str(uuid.UUID(user["id"]))
            signed = self._smoke_http(
                "/auth/v1/token?grant_type=password",
                {"apikey": public_key},
                {"email": email, "password": password},
                "login",
            )
            if not isinstance(signed, dict) or not isinstance(signed.get("access_token"), str):
                raise RolloutError("smoke_login_invalid")
            phone = {"apikey": public_key, "Authorization": "Bearer " + signed["access_token"]}
            self._smoke_http("/rest/v1/rpc/ensure_my_online_account", phone, {}, "account", (200, 204))
            privacy = re.search(
                r"static const version = '([^']+)';",
                (self.root / "lib/services/privacy_notice.dart").read_text("utf-8"),
            )
            if privacy is None:
                raise RolloutError("privacy_version_missing")
            self._smoke_http(
                "/rest/v1/rpc/acknowledge_my_privacy_notice",
                phone,
                {"p_version": privacy.group(1), "p_age_16_confirmed": True},
                "privacy",
                (200, 204),
            )
            request_id = str(uuid.uuid4())
            initialized = self._smoke_http(
                "/functions/v1/execute-game-command",
                phone,
                {
                    "protocol": 2,
                    "clientBuild": self.args.minimum_client_build,
                    "action": "initialize_account",
                    "requestId": request_id,
                },
                "initialize",
            )
            replay = self._smoke_http(
                "/functions/v1/execute-game-command",
                phone,
                {
                    "protocol": 2,
                    "clientBuild": self.args.minimum_client_build,
                    "action": "initialize_account",
                    "requestId": request_id,
                },
                "initialize_replay",
            )
            snapshot = self._smoke_http(
                "/functions/v1/execute-game-command",
                phone,
                {"protocol": 2, "clientBuild": self.args.minimum_client_build, "action": "read_state"},
                "read",
            )
            if (
                not isinstance(initialized, dict)
                or not isinstance(replay, dict)
                or initialized.get("server_revision") != replay.get("server_revision")
                or not isinstance(snapshot, dict)
                or snapshot.get("ruleset_sha256") != self.new_ruleset
                or snapshot.get("authority_mode") != "server"
            ):
                raise RolloutError("smoke_contract_failed")
            return {
                "authenticated": True,
                "initializationReplay": True,
                "serverAuthority": True,
                "rulesetSha256": self.new_ruleset,
            }
        finally:
            try:
                self._cleanup_synthetic(run, owner)
                if transient_enabled:
                    self._verify_staging_dormant("staging_account_count_after_cleanup")
            except Exception as failure:
                cleanup_failure = failure
            try:
                if transient_enabled:
                    if transient_runtime is None:
                        raise RolloutError("smoke_runtime_state_missing")
                    self._update_runtime(
                        transient_runtime,
                        {
                            "enabled": candidate_runtime["enabled"],
                            "migration_enabled": candidate_runtime["migration_enabled"],
                        },
                        "smoke_runtime_restore",
                    )
            except Exception as failure:
                restore_failure = failure
            if restore_failure is not None:
                raise RolloutError("smoke_runtime_restore_failed") from restore_failure
            if cleanup_failure is not None:
                if isinstance(cleanup_failure, RolloutError):
                    raise cleanup_failure
                raise RolloutError("smoke_cleanup_failed") from cleanup_failure

    def _rollback(self) -> dict[str, object]:
        if self.baseline_runtime is None or self.baseline_function is None:
            raise RolloutError("rollback_baseline_missing")
        current = self._runtime()
        if not any(
            self._same_runtime_state(current, expected)
            for expected in self._owned_runtime_states()
        ):
            if current["enabled"] or current["migration_enabled"]:
                self._update_runtime(
                    current,
                    {"enabled": False, "migration_enabled": False},
                    "rollback_foreign_runtime_pause",
                )
            raise RolloutError("rollback_runtime_owned_by_other_rollout")
        paused = self._update_runtime(
            current,
            {"enabled": False, "migration_enabled": False},
            "rollback_pause",
        )
        current_function = self._function()
        restore_worker = False
        if current_function["ezbr_sha256"] == self.baseline_function["ezbr_sha256"]:
            restore_worker = False
        elif self.candidate_function is not None and self._same_function_state(
            current_function, self.candidate_function
        ):
            restore_worker = True
        elif (
            self.worker_deploy_attempted
            and self.candidate_function is None
            and current_function["version"] == self.baseline_function["version"] + 1
        ):
            current_ruleset = self._download(
                self.evidence / "rollback-current-worker",
                "rollback_current_worker_download",
            )
            if current_ruleset != self.new_ruleset:
                raise RolloutError("rollback_worker_owned_by_other_rollout")
            restore_worker = True
        else:
            raise RolloutError("rollback_worker_owned_by_other_rollout")
        if restore_worker:
            self._deploy(self.evidence / "baseline-worker", "rollback_worker_deploy")
        restored = self._update_runtime(
            paused,
            {
                "enabled": self.baseline_runtime["enabled"],
                "migration_enabled": self.baseline_runtime["migration_enabled"],
                "minimum_client_build": self.baseline_runtime["minimum_client_build"],
                "ruleset_sha256": self.baseline_runtime["ruleset_sha256"],
            },
            "rollback_runtime_restore",
        )
        final_function = self._function()
        if final_function["ezbr_sha256"] != self.baseline_function["ezbr_sha256"]:
            raise RolloutError("rollback_worker_not_restored")
        for key in RUNTIME_FIELDS:
            if restored[key] != self.baseline_runtime[key]:
                raise RolloutError("rollback_runtime_not_restored")
        result = {
            "restored": True,
            "runtime": restored,
            "function": final_function,
            "note": "ruleset_revision remains monotonic and is intentionally not decremented",
        }
        self._write("rollback.json", result)
        return result

    def execute(self) -> dict[str, object]:
        self.evidence.mkdir(parents=True, exist_ok=False)
        self._build_and_test()
        self._verify_migrations_and_lint()
        self._verify_release()
        self.baseline_runtime = self._runtime()
        self.baseline_function = self._function()
        old_ruleset = self._download(self.evidence / "baseline-worker", "baseline_worker_download")
        if self.baseline_runtime["ruleset_sha256"] is not None and old_ruleset != self.baseline_runtime["ruleset_sha256"]:
            raise RolloutError("baseline_worker_runtime_mismatch")
        if self.args.mode == "apply" and old_ruleset == self.new_ruleset:
            raise RolloutError("candidate_ruleset_not_new")
        if self.args.minimum_client_build < self.baseline_runtime["minimum_client_build"]:
            raise RolloutError("candidate_build_downgrade")
        baseline = {
            "environment": self.args.environment,
            "projectRef": self.project,
            "runtime": self.baseline_runtime,
            "function": self.baseline_function,
            "deployedRulesetSha256": old_ruleset,
            "candidateRulesetSha256": self.new_ruleset,
            "minimumClientBuild": self.args.minimum_client_build,
            "sourceRevision": self._run(["git", "rev-parse", "HEAD"], "source_revision").strip(),
        }
        self._write("baseline.json", baseline)
        if self.args.mode == "plan":
            result = {**baseline, "mode": "plan", "mutated": False}
            self._write("result.json", result)
            return result

        try:
            paused = self._update_runtime(
                self.baseline_runtime,
                {"enabled": False, "migration_enabled": False},
                "candidate_runtime_pause",
            )
            self.worker_deploy_attempted = True
            self._deploy(self.root, "candidate_worker_deploy")
            candidate_function = self._function()
            if candidate_function["version"] <= self.baseline_function["version"]:
                raise RolloutError("candidate_worker_version_not_advanced")
            self.candidate_function = candidate_function
            deployed_dir = self.evidence / "candidate-deployed"
            deployed_ruleset = self._download(deployed_dir, "candidate_worker_verify_download")
            if deployed_ruleset != self.new_ruleset:
                raise RolloutError("candidate_worker_ruleset_mismatch")
            candidate_runtime = self._update_runtime(
                paused,
                {
                    "enabled": self.baseline_runtime["enabled"],
                    "migration_enabled": self.baseline_runtime["migration_enabled"],
                    "minimum_client_build": self.args.minimum_client_build,
                    "ruleset_sha256": self.new_ruleset,
                },
                "candidate_runtime_activate",
            )
            self.candidate_runtime = candidate_runtime
            smoke = self._smoke(candidate_runtime)
            self._verify_migrations_and_lint()
            self._postflight()
            final_runtime = self._runtime()
            final_function = self._function()
            if not self._same_runtime_state(final_runtime, candidate_runtime):
                raise RolloutError("candidate_runtime_final_mismatch")
            if not self._same_function_state(final_function, candidate_function):
                raise RolloutError("candidate_worker_final_mismatch")
            result = {
                "mode": "apply",
                "environment": self.args.environment,
                "projectRef": self.project,
                "minimumClientBuild": self.args.minimum_client_build,
                "rulesetSha256": self.new_ruleset,
                "runtime": final_runtime,
                "function": final_function,
                "smoke": smoke,
                "rollbackRequired": False,
            }
            self._write("result.json", result)
            return result
        except Exception as failure:
            if (
                not self.worker_deploy_attempted
                and isinstance(failure, RolloutError)
                and str(failure) == "candidate_runtime_pause_concurrent_change"
            ):
                raise
            try:
                rollback = self._rollback()
            except Exception as rollback_failure:
                self._write(
                    "rollback-failure.json",
                    {
                        "automaticRollback": False,
                        "failure": type(failure).__name__,
                        "rollbackFailure": type(rollback_failure).__name__,
                        "operatorAction": "keep gameplay paused and restore from baseline-worker",
                    },
                )
                raise RolloutError("candidate_failed_and_rollback_failed") from rollback_failure
            self._write(
                "failure.json",
                {"candidateFailure": type(failure).__name__, "automaticRollback": rollback},
            )
            if isinstance(failure, RolloutError):
                raise
            raise RolloutError("candidate_rollout_failed") from failure


def _arguments(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--environment", choices=sorted(PROJECTS), required=True)
    parser.add_argument("--mode", choices=("plan", "apply"), required=True)
    parser.add_argument("--minimum-client-build", type=int, required=True)
    parser.add_argument("--evidence-dir", required=True)
    parser.add_argument("--supabase", default="supabase")
    parser.add_argument("--dart", default="dart")
    parser.add_argument("--deno", default="deno")
    parser.add_argument("--pwsh", default="pwsh")
    parser.add_argument("--expected-url")
    parser.add_argument("--expected-publishable-key")
    parser.add_argument("--release-tag")
    parser.add_argument("--apk-sha256", type=str.lower)
    parser.add_argument("--github-repository", default="Rakky88/DragonHaven")
    args = parser.parse_args(argv)
    if args.minimum_client_build < 1 or BUILD.fullmatch(str(args.minimum_client_build)) is None:
        parser.error("minimum client build is invalid")
    if args.mode == "apply" and args.environment == "production":
        if not args.release_tag or not args.apk_sha256:
            parser.error("production apply requires --release-tag and --apk-sha256")
    if args.mode == "apply" and args.environment == "staging":
        if not args.expected_url or not args.expected_publishable_key:
            parser.error(
                "staging apply requires --expected-url and --expected-publishable-key"
            )
    return args


def main(argv: list[str] | None = None) -> int:
    args = _arguments(sys.argv[1:] if argv is None else argv)
    try:
        result = Rollout(args).execute()
    except RolloutError as error:
        print("FAIL: " + str(error), file=sys.stderr)
        return 1
    print(json.dumps({
        "status": "planned" if args.mode == "plan" else "applied",
        "environment": args.environment,
        "rulesetSha256": result.get("candidateRulesetSha256", result.get("rulesetSha256")),
        "minimumClientBuild": args.minimum_client_build,
        "evidenceDir": str(Path(args.evidence_dir).resolve()),
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
