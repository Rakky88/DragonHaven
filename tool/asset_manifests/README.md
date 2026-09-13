# Lossless runtime artwork

`lossless_v35.json` records every byte replacement and retired file for the
v0.05.35 APK reduction. It is generated only after independent Pillow and Flutter
decoder comparisons. File dimensions, all source RGBA pixels, color profiles and
Flutter's premultiplied RGBA output must match. A smaller encoding that fails
either decoder check is rejected. PNG recompression is the same-format fallback.

Original bytes are preserved locally under `artwork_sources/lossless_v35/`, which
is deliberately excluded from Flutter assets and Git by the existing repository
policy. They also remain reproducibly available from each manifest source path
at `baselineSourceCommit`; SHA-256 values identify the exact originals. No
original is discarded merely because the runtime file is smaller.

The twelve retired dragon sprites are superseded by the existing `_safe_v2`
selection in `DragonArtwork.secondPassStandaloneForms`. Three art-prompt JSONs
are source documentation, not runtime data. Asset inventory tests prevent them
from returning to the APK or replacing the selected dragon forms.

For new artwork, preserve the source first and generate candidates outside
`assets/`. Do not write a newly generated PNG beside a converted WebP with the
same logical name. Review both decoders again, update the runtime path mapping,
and record new source/runtime hashes in the manifest. Do not refresh hashes to
hide an unreviewed image change. Source-generation tools still produce original
PNGs; use their output as review input, not as an additional bundled duplicate.

The v35 audit can be reproduced from the baseline checkout with:

```powershell
python tool/optimize_runtime_images.py --source-apk build/app/outputs/flutter-apk/app-release.apk --output-dir .tools/lossless35 --workers 4
python tool/optimize_runtime_pngs.py
flutter test test/lossless_candidate_review_test.dart --dart-define=REVIEW_LOSSLESS_CANDIDATES=true
flutter test test/lossless_candidate_review_test.dart --dart-define=REVIEW_LOSSLESS_CANDIDATES=true --dart-define=LOSSLESS_PROOF_FOLDER=png-proofs
```

The one-time application tool additionally needs the reviewed twelve-path
retirement list in `.tools/retired35.json`. Its source is the above dragon map.
After application, verify all archived sources against installed runtime files:

```powershell
flutter test test/lossless_candidate_review_test.dart --dart-define=REVIEW_APPLIED_LOSSLESS_ASSETS=true
flutter test test/runtime_asset_inventory_test.dart
```

The ordinary inventory test needs no local archive. The opt-in pixel review
requires the original archive, which can be restored from the baseline commit
and verified against the manifest's source hashes.
