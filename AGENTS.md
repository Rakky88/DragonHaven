# DragonHaven release requirement

Before publishing any DragonHaven release, run
`tool/release_server_preflight.ps1` against the linked Supabase project. Do not
publish when migrations differ, database lint reports an error, or either
public Auth endpoint is unhealthy. This preflight is mandatory in addition to
Flutter analysis, tests, APK signature/version checks and the GitHub publisher
dry run.

# Living gameplay reference requirement

Changes to Special Events, Special Adventures, Special Chests, or egg content
must update `SPECIAL_EVENTS_CHESTS_AND_EGGS.md` in the same change. Changes to
any random reward, probability, weighted pool, range, pity rule, conditional
chance, or no-duplicate rule must update `RANDOM_REWARDS_AND_ODDS.md` in the
same change. A change may require both documents.

After reviewing the affected document content, run
`dart run tool/reference_documentation_guard.dart --update`, then
`dart run tool/reference_documentation_guard.dart --verify` and
`flutter test test/reference_documentation_test.dart`. Never refresh a
fingerprint without first checking that the player-facing tables and content
relationships still match the implementation. When randomness is introduced
in a new source file, add that file to the appropriate source list in
`tool/reference_documentation_guard.dart`.
