# Release 0.05.40 / 10090 verification

Based on published 0.05.39. Shared expertise formulas and removal of all seasonal
score/action ceilings; Birthday is endless with one-miss completion. Detailed
rules: TRIAL_EXPERTISE.md. Authority cutover remains dormant and out of scope.

- Full Flutter suite: 983 passed, one existing opt-in skip, two failures corrected
  (original UTF-8 phrase encoding and migration-version expectation). The entire
  six affected/version/reference test files then passed: 100/100, resolving both.
- Dedicated tests cover formula boundaries, 90.6-second Valentine/Pride play
  beyond 20,000 points and 200 actions, and 6,000 Birthday layers with repeated
  bounded checkpoint restore and one-miss termination.
- Native/JavaScript model parity passed, bundle 1,238,078 bytes.
- Staging migration-87 rehearsal passed all four rollback contracts: shared
  expertise, six uncapped seasonal scores/endless Birthday, endless New Year,
  and canonical event points. Authority flags and real player data unchanged.
- The separate account repair is backed up with private encrypted evidence;
  no player snapshots, tokens or identifying data are committed. Physical phone
  tag/untag succeeds; pending operation cleared; repaired scores and inventory
  confirmed in the new cloud revision.

Final server apply, native visual checks, build/signature and publication are
pending; this file will record their actual results before completion.
