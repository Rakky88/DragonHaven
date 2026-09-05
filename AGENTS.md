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

# Living redeem-code reference requirement

Adding, removing, redirecting, or changing the reward of any redeem code must
update `REDEEM_CODES.md` in the same change. The active-code catalog belongs in
`lib/models/redeem_code.dart`; do not hide additional production codes in UI or
provider files. If a referenced reward changes, review the exact contents in
the redeem-code document as well. Run the same documentation guard update,
verification, and reference-documentation test described above.

Redeem codes are private operational data and must never be included in public
release notes. Before publishing, verify that every `release-notes-*.md` file
is free of active code values and of language that announces redeem codes.

# Dragon sprite direction requirement

Every newly generated or regenerated DragonHaven dragon sprite must show both
the head/snout and the torso/body axis pointing toward screen-right. This
applies to Hatchlings, Wyrmlings, every ascended form, Mastery forms and
Spectral variants. Do not accept a front-facing or left-facing render. Keep the
entire body inside generous transparent padding and verify that no matte or
background remnants remain before adding the asset to the game.
