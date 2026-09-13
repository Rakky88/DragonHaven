"""Apply reviewed image candidates, preserving original bytes outside the APK.

Requires both completed encoder reports and the opt-in Flutter decoder review.
Run from the repository root. No candidate without exact renderer equality is
eligible. The manifest is the reproducible provenance and rollback inventory.
"""
import json
from pathlib import Path
import shutil
import zipfile

from optimize_runtime_images import digest


def main():
    root = Path.cwd().resolve()
    output = root / '.tools/lossless35'
    report = json.loads((output/'report.json').read_text())
    baseline = root/'.tools/release34-baseline.apk'
    if not baseline.exists():
        baseline = root/'build/app/outputs/flutter-apk/app-release.apk'
    assert digest(baseline.read_bytes()) == report['sourceApkSha256']
    with zipfile.ZipFile(baseline) as apk:
        packed_sizes = {entry.filename.removeprefix('assets/flutter_assets/'): entry.compress_size
                        for entry in apk.infolist()}
    reviews = {}
    selected = {}
    for folder in ('proofs', 'png-proofs'):
        review = json.loads((output/f'flutter-decoder-{folder}.json').read_text())
        reviews[folder] = review
        passed = set(review['accepted'])
        rows = [json.loads(p.read_text()) for p in (output/folder).rglob('*.json')]
        assert review['checked'] == sum(r['accepted'] for r in rows), 'Incomplete decoder review'
        for row in rows:
            if row['source'] not in passed:
                continue
            previous = selected.get(row['source'])
            if previous is None or row['savingBytes'] > previous['savingBytes']:
                selected[row['source']] = row
    retired = json.loads((root/'.tools/retired35.json').read_text())
    retired += ['assets/images/egg_altar/ART_PROMPTS.json',
                'assets/images/events/golden_wings/ART_PROMPTS.json',
                'assets/images/events/halloween/ARCANA_ART_PROMPTS.json']
    archive_root = root / 'artwork_sources/lossless_v35'
    assert not (archive_root/'manifest.json').exists(), 'Already applied'
    planned = []
    for source_name in sorted(set(selected) | set(retired)):
        source = root/source_name
        assert source.resolve().is_relative_to(root/'assets/images')
        archived = archive_root/source_name
        assert archived.resolve().is_relative_to(archive_root)
        assert source.is_file() and not archived.exists()
        raw = source.read_bytes()
        row = selected.get(source_name)
        if source_name in retired:
            planned.append(dict(source=source_name, archive=archived.relative_to(root).as_posix(),
                                sourceSha256=digest(raw), sourceBytes=len(raw), retired=True,
                                packedBytes=packed_sizes[source_name], savingBytes=packed_sizes[source_name]))
            continue
        assert digest(raw) == row['sourceSha256']
        candidate = root/row['candidate']
        assert candidate.resolve().is_relative_to(output)
        assert digest(candidate.read_bytes()) == row['candidateSha256']
        target = source.with_suffix(candidate.suffix)
        assert target == source or not target.exists(), f'Collision: {target}'
        planned.append(dict(row, archive=archived.relative_to(root).as_posix(),
                            runtime=target.relative_to(root).as_posix(),
                            flutterRgbaExact=True, retired=False))
    # Validate all paths and hashes before the first file mutation.
    for row in planned:
        source = root/row['source']
        archived = root/row['archive']
        archived.parent.mkdir(parents=True, exist_ok=True)
        source.rename(archived)
        if not row['retired']:
            shutil.copyfile(root/row['candidate'], root/row['runtime'])
    png_map = {r['source']: r['runtime'] for r in planned
               if not r['retired'] and r['source'] != r['runtime']}
    # Replace literal asset paths only; logical IDs and dynamic paths are
    # resolved by runtimeImageAsset. Source-generation tools retain originals.
    paths = [*Path('lib').rglob('*.dart'), *Path('test').rglob('*.dart'), Path('pubspec.yaml')]
    for path in paths:
        if path.name == 'runtime_image_assets.dart':
            continue
        text = path.read_text(encoding='utf-8')
        changed = text
        for old, new in png_map.items():
            changed = changed.replace(old, new)
            for token in ('$_schoolAssetRoot', '$_schoolIconRoot'):
                prefix = 'assets/images/ui/dragon_school'
                if old.startswith(prefix+'/'):
                    changed = changed.replace(old.replace(prefix, token), new.replace(prefix, token))
        if path.name == 'pubspec.yaml':
            # Launcher tooling still uses the original source raster.
            for old, new in png_map.items():
                changed = changed.replace('adaptive_icon_foreground: '+new,
                                          'adaptive_icon_foreground: artwork_sources/lossless_v35/'+old)
        if changed != text:
            path.write_text(changed, encoding='utf-8')
    helper = Path('lib/runtime_image_assets.dart')
    text = helper.read_text(encoding='utf-8')
    text = text.replace('const losslessPngAssets = <String>{};',
                        'const losslessPngAssets = <String>{\n'+
                        ''.join("  '"+p+"',\n" for p in sorted(png_map))+'};')
    helper.write_text(text, encoding='utf-8')
    manifest = dict(baselineApkSha256=report['sourceApkSha256'],
                    baselineSourceCommit='ea622d8127b470b73bbf4b35dbc5345c87ffddb3',
                    baselineApkBytes=628260114, imageRows=planned,
                    encoderChecked=report['checked'],
                    rendererRejectedWebp=len(reviews['proofs']['rejected']),
                    rendererRejectedPng=len(reviews['png-proofs']['rejected']),
                    optimizedCount=sum(not r['retired'] for r in planned),
                    retiredCount=len(retired),
                    imageSavingBytes=sum(r.get('savingBytes', r['sourceBytes']) for r in planned),
                    convertedPngCount=len(png_map))
    (archive_root/'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    tracked_manifest = root/'tool/asset_manifests/lossless_v35.json'
    tracked_manifest.parent.mkdir(parents=True, exist_ok=True)
    tracked_manifest.write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    print(json.dumps({k:v for k,v in manifest.items() if k != 'imageRows'}, indent=2))


if __name__ == '__main__':
    main()
