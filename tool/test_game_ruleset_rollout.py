import hashlib
import argparse
import json
from pathlib import Path
import tempfile
import unittest

from tool.game_ruleset_rollout import (
    RolloutError,
    _json_from_output,
    _local_versions,
    _ruleset_from,
    _safe_runtime,
    _semantic_version,
    _sql,
    Rollout,
)


class GameRulesetRolloutTest(unittest.TestCase):
    def test_release_versions_compare_numerically_with_display_padding(self):
        self.assertEqual(_semantic_version("0.6.9"), (0, 6, 9))
        self.assertEqual(_semantic_version("0.06.09"), (0, 6, 9))
        self.assertIsNone(_semantic_version("v0.06.09"))
        self.assertIsNone(_semantic_version("0.6"))

    def test_extracts_final_cli_json(self):
        value = _json_from_output('notice\n{"migrations":[{"remote":"1"}]}\n')
        self.assertEqual(value, {"migrations": [{"remote": "1"}]})

    def test_generated_bundle_must_match_exported_hash(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / "supabase/functions/execute-game-command"
            target.mkdir(parents=True)
            bundle = b"globalThis.example = true;\n"
            digest = hashlib.sha256(bundle).hexdigest()
            (target / "game.generated.js").write_bytes(bundle)
            (target / "bundle.generated.ts").write_text(
                f"export const ruleset = '{digest}';\n", "utf-8"
            )
            self.assertEqual(_ruleset_from(root), digest)
            (target / "game.generated.js").write_bytes(bundle + b"changed")
            with self.assertRaisesRegex(RolloutError, "generated_ruleset_hash_mismatch"):
                _ruleset_from(root)

    def test_runtime_filter_rejects_missing_or_unsafe_values(self):
        runtime = {
            "singleton": True,
            "enabled": True,
            "migration_enabled": True,
            "minimum_client_build": 10102,
            "ruleset_sha256": "a" * 64,
            "ruleset_revision": 3,
            "shadow_social_enabled": False,
            "shadow_projection_enabled": False,
            "shadow_lifecycle_enabled": False,
            "updated_at": "2026-09-24T12:00:00+00:00",
            "ignored_future_field": "not exported",
        }
        filtered = _safe_runtime(runtime)
        self.assertNotIn("ignored_future_field", filtered)
        broken = dict(runtime)
        broken["ruleset_sha256"] = "unsafe"
        with self.assertRaisesRegex(RolloutError, "runtime_ruleset_invalid"):
            _safe_runtime(broken)

    def test_sql_literals_are_bounded_and_escaped(self):
        self.assertEqual(_sql(None), "null")
        self.assertEqual(_sql(True), "true")
        self.assertEqual(_sql(10102), "10102")
        self.assertEqual(_sql("it's"), "'it''s'")
        with self.assertRaisesRegex(RolloutError, "unsafe_sql_value"):
            _sql(["no"])

    def test_local_migrations_require_unique_numeric_prefixes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / "supabase/migrations"
            target.mkdir(parents=True)
            (target / "001_first.sql").write_text("select 1;", "utf-8")
            (target / "002_second.sql").write_text("select 2;", "utf-8")
            self.assertEqual(_local_versions(root), ["001", "002"])
            (target / "002_duplicate.sql").write_text("select 3;", "utf-8")
            with self.assertRaisesRegex(RolloutError, "local_migration_history_invalid"):
                _local_versions(root)

    def test_runtime_update_is_guarded_by_complete_baseline(self):
        with tempfile.TemporaryDirectory() as directory:
            args = argparse.Namespace(
                environment="staging",
                mode="plan",
                minimum_client_build=10102,
                evidence_dir=directory,
                supabase="supabase",
                dart="dart",
                deno="deno",
                pwsh="pwsh",
                expected_url="https://vtmjkhzalalozpfnbvsd.supabase.co",
                expected_publishable_key="sb_publishable_test",
                release_tag=None,
                apk_sha256=None,
                github_repository="Rakky88/DragonHaven",
            )
            rollout = Rollout(args)
            runtime = self.runtime()
            updated = dict(runtime, enabled=False, updated_at="2026-09-24T12:00:01+00:00")
            captured = []

            def query(sql, label, read_only=False):
                captured.append((sql, label, read_only))
                return [{"runtime": updated}]

            rollout._query = query
            self.assertEqual(
                rollout._update_runtime(runtime, {"enabled": False}, "guarded_update"),
                _safe_runtime(updated),
            )
            sql = captured[0][0]
            self.assertIn("where r.singleton", sql)
            self.assertIn("r.updated_at is not distinct from", sql)
            for field in (
                "enabled",
                "migration_enabled",
                "minimum_client_build",
                "ruleset_sha256",
                "shadow_social_enabled",
                "shadow_projection_enabled",
                "shadow_lifecycle_enabled",
            ):
                self.assertIn(f"r.{field} is not distinct from", sql)

    def test_plan_is_remote_read_only_and_failure_restores_worker_and_runtime(self):
        with tempfile.TemporaryDirectory() as directory:
            plan = FakeRollout(self.args(Path(directory) / "plan", "plan"))
            result = plan.execute()
            self.assertFalse(result["mutated"])
            self.assertEqual(plan.deployments, [])
            self.assertEqual(plan.runtime_updates, [])

            failed = FakeRollout(self.args(Path(directory) / "apply", "apply"), fail_smoke=True)
            with self.assertRaisesRegex(RolloutError, "simulated_smoke_failure"):
                failed.execute()
            self.assertEqual(failed.function["ezbr_sha256"], "1" * 64)
            for key in (
                "enabled",
                "migration_enabled",
                "minimum_client_build",
                "ruleset_sha256",
                "shadow_social_enabled",
                "shadow_projection_enabled",
                "shadow_lifecycle_enabled",
            ):
                self.assertEqual(failed.current[key], failed.initial[key])
            rollback = json.loads((Path(directory) / "apply" / "rollback.json").read_text("utf-8"))
            self.assertTrue(rollback["restored"])
            self.assertEqual(failed.deployments, ["candidate", "baseline"])

    def test_lost_pause_response_restores_runtime_without_redeploying_worker(self):
        with tempfile.TemporaryDirectory() as directory:
            failed = FakeRollout(
                self.args(Path(directory) / "apply", "apply"),
                fail_pause_response=True,
            )
            with self.assertRaisesRegex(RolloutError, "simulated_pause_response_loss"):
                failed.execute()
            for key in (
                "enabled",
                "migration_enabled",
                "minimum_client_build",
                "ruleset_sha256",
                "shadow_social_enabled",
                "shadow_projection_enabled",
                "shadow_lifecycle_enabled",
            ):
                self.assertEqual(failed.current[key], failed.initial[key])
            self.assertEqual(failed.deployments, [])
            rollback = json.loads(
                (Path(directory) / "apply" / "rollback.json").read_text("utf-8")
            )
            self.assertTrue(rollback["restored"])

    def test_postflight_failure_participates_in_automatic_rollback(self):
        with tempfile.TemporaryDirectory() as directory:
            failed = FakeRollout(
                self.args(Path(directory) / "apply", "apply"),
                fail_postflight=True,
            )
            with self.assertRaisesRegex(RolloutError, "simulated_postflight_failure"):
                failed.execute()
            self.assertEqual(failed.postflights, 1)
            self.assertEqual(failed.deployments, ["candidate", "baseline"])
            for key in (
                "enabled",
                "migration_enabled",
                "minimum_client_build",
                "ruleset_sha256",
                "shadow_social_enabled",
                "shadow_projection_enabled",
                "shadow_lifecycle_enabled",
            ):
                self.assertEqual(failed.current[key], failed.initial[key])

    def test_concurrent_runtime_change_is_paused_without_being_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            failed = FakeRollout(
                self.args(Path(directory) / "apply", "apply"),
                mutate_during_postflight=True,
            )
            with self.assertRaisesRegex(
                RolloutError, "candidate_failed_and_rollback_failed"
            ):
                failed.execute()
            self.assertEqual(failed.current["minimum_client_build"], 10103)
            self.assertFalse(failed.current["enabled"])
            self.assertFalse(failed.current["migration_enabled"])
            self.assertEqual(failed.current["ruleset_sha256"], "b" * 64)
            self.assertEqual(failed.deployments, ["candidate"])
            self.assertTrue(
                (Path(directory) / "apply" / "rollback-failure.json").is_file()
            )

    def test_dormant_staging_check_requires_zero_canonical_accounts(self):
        with tempfile.TemporaryDirectory() as directory:
            rollout = Rollout(self.args(Path(directory) / "evidence", "plan"))
            rollout._query = lambda sql, label, read_only=False: [{"accounts": 0}]
            rollout._verify_staging_dormant("before")
            rollout._query = lambda sql, label, read_only=False: [{"accounts": 1}]
            with self.assertRaisesRegex(RolloutError, "dormant_smoke_not_isolated"):
                rollout._verify_staging_dormant("after")

    @staticmethod
    def runtime():
        return {
            "singleton": True,
            "enabled": True,
            "migration_enabled": True,
            "minimum_client_build": 10101,
            "ruleset_sha256": "a" * 64,
            "ruleset_revision": 3,
            "shadow_social_enabled": False,
            "shadow_projection_enabled": False,
            "shadow_lifecycle_enabled": False,
            "updated_at": "2026-09-24T12:00:00+00:00",
        }

    @staticmethod
    def args(evidence, mode):
        return argparse.Namespace(
            environment="staging",
            mode=mode,
            minimum_client_build=10102,
            evidence_dir=str(evidence),
            supabase="supabase",
            dart="dart",
            deno="deno",
            pwsh="pwsh",
            expected_url="https://vtmjkhzalalozpfnbvsd.supabase.co",
            expected_publishable_key="sb_publishable_test",
            release_tag=None,
            apk_sha256=None,
            github_repository="Rakky88/DragonHaven",
        )


class FakeRollout(Rollout):
    def __init__(
        self,
        args,
        fail_smoke=False,
        fail_pause_response=False,
        fail_postflight=False,
        mutate_during_postflight=False,
    ):
        super().__init__(args)
        self.initial = GameRulesetRolloutTest.runtime()
        self.current = dict(self.initial)
        self.function = {
            "slug": "execute-game-command",
            "status": "ACTIVE",
            "verify_jwt": False,
            "version": 9,
            "ezbr_sha256": "1" * 64,
        }
        self.fail_smoke = fail_smoke
        self.fail_pause_response = fail_pause_response
        self.fail_postflight = fail_postflight
        self.mutate_during_postflight = mutate_during_postflight
        self.deployments = []
        self.runtime_updates = []
        self.postflights = 0

    def _build_and_test(self):
        self.new_ruleset = "b" * 64

    def _verify_migrations_and_lint(self):
        return None

    def _verify_release(self):
        return None

    def _postflight(self):
        self.postflights += 1
        if self.mutate_during_postflight:
            self.current["minimum_client_build"] = 10103
            self.current["updated_at"] = "2026-09-24T12:01:00+00:00"
        if self.fail_postflight:
            raise RolloutError("simulated_postflight_failure")

    def _runtime(self):
        return dict(self.current)

    def _function(self):
        return dict(self.function)

    def _download(self, destination, label):
        destination.mkdir(parents=True, exist_ok=False)
        return self.initial["ruleset_sha256"] if "baseline" in destination.name else self.new_ruleset

    def _update_runtime(self, expected, changes, label):
        self.assert_expected(expected)
        previous_hash = self.current["ruleset_sha256"]
        self.current.update(changes)
        if self.current["ruleset_sha256"] != previous_hash:
            self.current["ruleset_revision"] += 1
        self.current["updated_at"] = f"2026-09-24T12:00:{len(self.runtime_updates) + 1:02d}+00:00"
        self.runtime_updates.append((label, dict(changes)))
        if label == "candidate_runtime_pause" and self.fail_pause_response:
            raise RolloutError("simulated_pause_response_loss")
        return dict(self.current)

    def assert_expected(self, expected):
        for key in (*self.initial.keys(),):
            if expected[key] != self.current[key]:
                raise AssertionError(f"unguarded runtime update for {key}")

    def _deploy(self, source, label):
        if Path(source).name == "baseline-worker":
            self.deployments.append("baseline")
            self.function.update(version=self.function["version"] + 1, ezbr_sha256="1" * 64)
        else:
            self.deployments.append("candidate")
            self.function.update(version=self.function["version"] + 1, ezbr_sha256="2" * 64)

    def _smoke(self, candidate_runtime):
        if self.fail_smoke:
            raise RolloutError("simulated_smoke_failure")
        return {"authenticated": True}

    def _run(self, command, label, cwd=None):
        if command[:2] == ["git", "rev-parse"]:
            return "f" * 40 + "\n"
        return ""


if __name__ == "__main__":
    unittest.main()
