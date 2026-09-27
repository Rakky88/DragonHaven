import hashlib
import argparse
import json
import shutil
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
    _worker_source_sha256,
    Rollout,
)


class GameRulesetRolloutTest(unittest.TestCase):
    def test_release_versions_compare_numerically_with_display_padding(self):
        self.assertEqual(_semantic_version("0.6.9"), (0, 6, 9))
        self.assertEqual(_semantic_version("0.06.09"), (0, 6, 9))
        self.assertIsNone(_semantic_version("v0.06.09"))
        self.assertIsNone(_semantic_version("0.6"))

    def test_release_allows_a_compatible_floor_below_the_tagged_build(self):
        with tempfile.TemporaryDirectory() as directory:
            rollout = Rollout(self.production_args(Path(directory) / "evidence", 10102))
            rollout.root = Path(directory)
            (rollout.root / "pubspec.yaml").write_text(
                "name: dragon_haven\nversion: 0.6.10+10103\n", "utf-8"
            )
            rollout._run = lambda command, label, cwd=None: (
                "f" * 40 + "\trefs/tags/v0.06.10\n"
                if label == 'release_remote_source_resolve' else "f" * 40 + "\n"
            )
            rollout._request = lambda *args, **kwargs: self.release_response()

            rollout._verify_release()

    def test_release_rejects_a_floor_above_the_tagged_build(self):
        with tempfile.TemporaryDirectory() as directory:
            rollout = Rollout(self.production_args(Path(directory) / "evidence", 10104))
            rollout.root = Path(directory)
            (rollout.root / "pubspec.yaml").write_text(
                "name: dragon_haven\nversion: 0.6.10+10103\n", "utf-8"
            )
            with self.assertRaisesRegex(
                RolloutError, "release_minimum_build_exceeds_source"
            ):
                rollout._verify_release()

    def test_prepublication_verifies_remote_candidate_and_public_baseline(self):
        with tempfile.TemporaryDirectory() as directory:
            rollout = self.prepublication_fixture(Path(directory))
            requests = []

            def request(url, **kwargs):
                requests.append(url)
                return self.release_response()

            rollout._request = request
            rollout._verify_release()
            rollout._verify_prepublication_staging()
            self.assertTrue(any(url.endswith('/releases/tags/v0.06.10') for url in requests))
            self.assertFalse(any('v0.06.11' in url for url in requests))

    def test_prepublication_rejects_dirty_or_unpushed_source(self):
        with tempfile.TemporaryDirectory() as directory:
            for label, output, error in (
                ('release_source_clean_check', ' M lib/domain/trial_attempts.dart', 'release_source_has_uncommitted_changes'),
                ('release_untracked_source_check', 'lib/domain/new_rules.dart', 'release_source_has_untracked_files'),
                ('release_remote_source_resolve', '', 'release_remote_source_not_exact'),
                ('release_remote_source_resolve', 'e' * 40 + '\trefs/heads/feat/server-owned-gameplay\n', 'release_remote_source_not_exact'),
                ('release_remote_source_resolve', 'f' * 40 + '\trefs/tags/v0.06.11\n', 'release_remote_source_not_exact'),
            ):
                with self.subTest(label=label, output=output):
                    rollout = self.prepublication_fixture(Path(directory))
                    run = rollout._run
                    rollout._run = lambda command, step, cwd=None: output if step == label else run(command, step, cwd)
                    with self.assertRaisesRegex(RolloutError, error):
                        rollout._verify_release()

    def test_published_release_accepts_peeled_annotated_remote_tag(self):
        with tempfile.TemporaryDirectory() as directory:
            rollout = self.prepublication_fixture(Path(directory))
            run = rollout._run
            rollout._run = lambda command, label, cwd=None: (
                'e' * 40 + '\trefs/tags/v0.06.11\n' + 'f' * 40 + '\trefs/tags/v0.06.11^{}\n'
                if label == 'release_remote_source_resolve' else run(command, label, cwd)
            )
            rollout._verify_remote_source('f' * 40, 'refs/tags/v0.06.11', annotated=True)

    def test_prepublication_still_rejects_wrong_public_apk_digest(self):
        with tempfile.TemporaryDirectory() as directory:
            rollout = self.prepublication_fixture(Path(directory))
            rollout.args.apk_sha256 = 'd' * 64
            with self.assertRaisesRegex(RolloutError, 'public_release_not_verified'):
                rollout._verify_release()

    def test_prepublication_cannot_raise_or_lower_existing_client_floor(self):
        with tempfile.TemporaryDirectory() as directory:
            for floor in (10101, 10103):
                with self.subTest(floor=floor):
                    rollout = self.prepublication_fixture(Path(directory))
                    rollout.args.minimum_client_build = floor
                    with self.assertRaisesRegex(RolloutError, 'compatible_rollout_cannot_change_minimum_build'):
                        rollout._verify_prepublication_staging()

    def test_prepublication_requires_successful_same_source_schema_and_worker_staging(self):
        with tempfile.TemporaryDirectory() as directory:
            for key, value in (
                ('sourceRevision', 'e' * 40),
                ('migrationVersions', ['099']),
                ('rulesetSha256', 'c' * 64),
                ('workerSourceSha256', 'c' * 64),
                ('rollbackRequired', True),
                ('mode', 'plan'),
                ('smoke', {'authenticated': True}),
                ('runtime', {'enabled': True}),
            ):
                with self.subTest(key=key):
                    rollout = self.prepublication_fixture(Path(directory))
                    path = Path(rollout.args.staging_evidence_dir) / 'result.json'
                    result = json.loads(path.read_text('utf-8'))
                    result[key] = value
                    path.write_text(json.dumps(result), 'utf-8')
                    with self.assertRaisesRegex(RolloutError, 'compatible_rollout_staging_evidence_mismatch'):
                        rollout._verify_prepublication_staging()

    def test_prepublication_rehashes_staged_parser_independently_of_ruleset(self):
        with tempfile.TemporaryDirectory() as directory:
            rollout = self.prepublication_fixture(Path(directory))
            core = Path(rollout.args.staging_evidence_dir) / 'candidate-deployed/supabase/functions/execute-game-command/core.ts'
            core.write_text('different capability parser', 'utf-8')
            with self.assertRaisesRegex(RolloutError, 'compatible_rollout_staging_worker_mismatch'):
                rollout._verify_prepublication_staging()

    def test_missing_staging_blocks_before_production_pause_or_deploy(self):
        with tempfile.TemporaryDirectory() as directory:
            args = self.production_args(Path(directory) / 'evidence', 10101)
            args.compatibility_release_tag = 'v0.06.09'
            args.staging_evidence_dir = str(Path(directory) / 'missing')
            rollout = FakeRollout(args)
            with self.assertRaisesRegex(RolloutError, 'compatible_rollout_staging_evidence_unavailable'):
                rollout.execute()
            self.assertEqual(rollout.runtime_updates, [])
            self.assertEqual(rollout.deployments, [])

    @classmethod
    def prepublication_fixture(cls, root):
        args = cls.production_args(root / 'production', 10102)
        args.release_tag = 'v0.06.11'
        args.compatibility_release_tag = 'v0.06.10'
        args.candidate_branch = 'feat/server-owned-gameplay'
        args.staging_evidence_dir = str(root / 'staging')
        rollout = Rollout(args)
        rollout.root = root
        rollout.new_ruleset = 'b' * 64
        rollout.migration_versions = ['099', '100']
        rollout.baseline_runtime = dict(cls.runtime(), minimum_client_build=10102)
        (root / 'pubspec.yaml').write_text('version: 0.6.11+10104\n', 'utf-8')
        worker = root / 'supabase/functions/execute-game-command'
        worker.mkdir(parents=True, exist_ok=True)
        for name in ('index.ts', 'core.ts', 'deadline.ts', 'bundle.generated.ts', 'game.generated.js'):
            (worker / name).write_text(name, 'utf-8')
        staging = Path(args.staging_evidence_dir)
        shutil.copytree(root / 'supabase', staging / 'candidate-deployed/supabase', dirs_exist_ok=True)
        runtime = dict(rollout.baseline_runtime, enabled=False, migration_enabled=False, ruleset_sha256=rollout.new_ruleset)
        result = {
            'environment': 'staging', 'projectRef': 'vtmjkhzalalozpfnbvsd', 'mode': 'apply',
            'rollbackRequired': False, 'sourceRevision': 'f' * 40,
            'rulesetSha256': rollout.new_ruleset, 'minimumClientBuild': 10102,
            'migrationVersions': rollout.migration_versions,
            'workerSourceSha256': _worker_source_sha256(root),
            'smoke': {'authenticated': True, 'initializationReplay': True, 'serverAuthority': True, 'rulesetSha256': rollout.new_ruleset},
            'runtime': runtime, 'function': {'status': 'ACTIVE', 'verify_jwt': False},
        }
        (staging / 'result.json').write_text(json.dumps(result), 'utf-8')
        (staging / 'baseline.json').write_text(json.dumps({'sourceRevision': 'f' * 40}), 'utf-8')
        (staging / 'server-postflight.txt').write_text('passed', 'utf-8')
        rollout._run = lambda command, label, cwd=None: (
            '' if label in ('release_source_clean_check', 'release_untracked_source_check', 'candidate_branch_invalid') else
            'f' * 40 + '\trefs/heads/feat/server-owned-gameplay\n' if label == 'release_remote_source_resolve' else 'f' * 40 + '\n'
        )
        rollout._request = lambda *args, **kwargs: cls.release_response()
        return rollout

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

    def test_successful_apply_records_exact_source_and_deployed_worker_for_promotion(self):
        with tempfile.TemporaryDirectory() as directory:
            rollout = FakeRollout(self.args(Path(directory) / 'staging', 'apply'))
            rollout.migration_versions = ['099', '100']
            result = rollout.execute()
            self.assertEqual(result['sourceRevision'], 'f' * 40)
            self.assertEqual(result['migrationVersions'], ['099', '100'])
            self.assertEqual(result['workerSourceSha256'], _worker_source_sha256(rollout.evidence / 'candidate-deployed'))
            self.assertFalse(result['rollbackRequired'])
            self.assertEqual(rollout.deployments, ['candidate'])

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

    @staticmethod
    def production_args(evidence, minimum_client_build):
        return argparse.Namespace(
            environment="production",
            mode="apply",
            minimum_client_build=minimum_client_build,
            evidence_dir=str(evidence),
            supabase="supabase",
            dart="dart",
            deno="deno",
            pwsh="pwsh",
            expected_url=None,
            expected_publishable_key=None,
            release_tag="v0.06.10",
            apk_sha256="a" * 64,
            github_repository="Rakky88/DragonHaven",
        )

    @staticmethod
    def release_response():
        return {
            "tag_name": "v0.06.10",
            "draft": False,
            "prerelease": False,
            "assets": [
                {
                    "name": "DragonHaven.apk",
                    "digest": "sha256:" + "a" * 64,
                    "size": 1,
                }
            ],
        }


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
        worker = destination / 'supabase/functions/execute-game-command'
        worker.mkdir(parents=True)
        for name in ('index.ts', 'core.ts', 'deadline.ts', 'bundle.generated.ts', 'game.generated.js'):
            (worker / name).write_text(name, 'utf-8')
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
