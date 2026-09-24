# DragonHaven v0.06.09 / 10102 verification

## Scope

This release adds three focus-specific Dragon Trials and their independent
rankings, applies the two-stage Trial rotation and Ascended-form unlock rules,
adds the final-evolution expertise gift, and improves Tower room clearing,
decoration placement information and bed rendering. Trial dismissal now uses
an optimistic update with server rollback, and the empty Trial state matches
the established DragonHaven presentation.

## Validation

Final source, test counts, device checks and artifact identity are recorded
here after the release candidate has passed the complete validation run.

## Server boundary

The release contains additive database migrations for Ascension expertise
capacity and the three new Trial ranking columns. Staging rehearsal,
production migration parity, database lint, public Auth health, application
health, worker activation and rollback evidence are recorded here after the
deployment checks complete.

## Artifact and publication

Package, version, signature, hashes, byte size, release URLs and workflow
results are recorded here after publication and independent download
verification.
