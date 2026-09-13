"""Plan lossless runtime-image replacements from an exact APK inventory.

Requires Pillow with WebP support. Source files are never modified by this tool.
Every accepted candidate has identical decoded RGBA pixels, dimensions and ICC
profile. Resume uses source hashes; candidates and proof records live separately.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import io
import json
from pathlib import Path
import time
import zipfile

from PIL import Image


def digest(data):
    return hashlib.sha256(data).hexdigest()


def optimize(job, output):
    path, packed_bytes = job
    source = path.read_bytes()
    proof_path = output / 'proofs' / (path.as_posix() + '.json')
    candidate_path = output / 'candidates' / path.with_suffix('.webp')
    if proof_path.exists():
        cached = json.loads(proof_path.read_text())
        if cached['sourceSha256'] == digest(source) and (
            not cached.get('accepted') or
            (candidate_path.exists() and digest(candidate_path.read_bytes()) == cached['candidateSha256'])
        ):
            return cached
    start = time.monotonic()
    row = {'source': path.as_posix(), 'sourceBytes': len(source),
           'packedBytes': packed_bytes, 'sourceSha256': digest(source),
           'accepted': False, 'savingBytes': 0}
    with Image.open(io.BytesIO(source)) as original:
        gamma = original.info.get('gamma')
        if getattr(original, 'is_animated', False) or original.mode not in ('RGB', 'RGBA', 'P', 'L', 'LA'):
            row['skipped'] = 'animation or unsupported bit depth'
        elif gamma is not None and abs(gamma - 0.45455) > 0.0001 and not original.info.get('icc_profile'):
            row['skipped'] = 'nonstandard gamma without an ICC profile'
        else:
            rgba = original.convert('RGBA')
            profile = original.info.get('icc_profile', b'')
            buffer = io.BytesIO()
            rgba.save(buffer, format='WEBP', lossless=True, quality=100,
                      method=6, exact=True, icc_profile=profile,
                      exif=original.info.get('exif', b''), xmp=original.info.get('xmp', b''))
            encoded = buffer.getvalue()
            with Image.open(io.BytesIO(encoded)) as decoded:
                assert decoded.size == original.size, path
                assert decoded.convert('RGBA').tobytes() == rgba.tobytes(), path
                assert decoded.info.get('icc_profile', b'') == profile, path
            row.update(candidateBytes=len(encoded), candidateSha256=digest(encoded),
                       rgbaSha256=digest(rgba.tobytes()), dimensions=list(original.size),
                       iccSha256=digest(profile), rgbaExact=True)
            # Flutter packages these images without ZIP compression. Using the
            # measured packed size also prevents optimistic savings estimates.
            if len(encoded) < packed_bytes:
                candidate_path.parent.mkdir(parents=True, exist_ok=True)
                candidate_path.write_bytes(encoded)
                row.update(accepted=True, savingBytes=packed_bytes-len(encoded),
                           candidate=candidate_path.as_posix())
    row['seconds'] = round(time.monotonic()-start, 3)
    proof_path.parent.mkdir(parents=True, exist_ok=True)
    proof_path.write_text(json.dumps(row, indent=2), encoding='utf-8')
    return row


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-apk', required=True, type=Path)
    parser.add_argument('--output-dir', required=True, type=Path)
    parser.add_argument('--workers', type=int, default=4)
    args = parser.parse_args()
    jobs = []
    prefix = 'assets/flutter_assets/'
    with zipfile.ZipFile(args.source_apk) as archive:
        for entry in archive.infolist():
            if entry.filename.startswith(prefix+'assets/images/') and entry.filename.endswith(('.png', '.webp')):
                path = Path(entry.filename[len(prefix):])
                assert path.resolve().is_relative_to(Path.cwd().resolve()), path
                assert digest(path.read_bytes()) == digest(archive.read(entry)), f'APK/source mismatch: {path}'
                jobs.append((path, entry.compress_size))
    jobs.sort(key=lambda job: job[1], reverse=True)
    rows = []
    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = [executor.submit(optimize, job, args.output_dir) for job in jobs]
        for future in as_completed(futures):
            rows.append(future.result())
            if len(rows) % 20 == 0 or len(rows) == len(jobs):
                print(json.dumps({'checked': len(rows), 'total': len(jobs),
                                  'accepted': sum(r['accepted'] for r in rows),
                                  'savingBytes': sum(r['savingBytes'] for r in rows)}), flush=True)
    report = {'sourceApkSha256': digest(args.source_apk.read_bytes()),
              'checked': len(rows), 'accepted': sum(r['accepted'] for r in rows),
              'savingBytes': sum(r['savingBytes'] for r in rows),
              'rows': sorted(rows, key=lambda row: row['source'])}
    (args.output_dir/'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')


if __name__ == '__main__':
    main()
