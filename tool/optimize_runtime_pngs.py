"""Produce same-format PNG fallbacks without changing pixels or color metadata."""
from concurrent.futures import ThreadPoolExecutor
import io
import json
from pathlib import Path
import struct
import zipfile

from PIL import Image, PngImagePlugin
from optimize_runtime_images import digest


def optimize(job):
    path, packed = job
    source = path.read_bytes()
    metadata = PngImagePlugin.PngInfo()
    offset = 8
    while offset < len(source):
        length = struct.unpack('>I', source[offset:offset+4])[0]
        kind = source[offset+4:offset+8]
        content = source[offset+8:offset+8+length]
        offset += length + 12
        if kind in (b'gAMA', b'cHRM', b'sRGB', b'sBIT'):
            metadata.add(kind, content)
    with Image.open(io.BytesIO(source)) as original:
        if getattr(original, 'is_animated', False):
            return
        encoded = io.BytesIO()
        original.save(encoded, format='PNG', optimize=True, compress_level=9,
                      pnginfo=metadata, icc_profile=original.info.get('icc_profile'),
                      exif=original.info.get('exif', b''))
        data = encoded.getvalue()
        if len(data) >= packed:
            return
        with Image.open(io.BytesIO(data)) as decoded:
            assert decoded.size == original.size
            assert decoded.convert('RGBA').tobytes() == original.convert('RGBA').tobytes()
            assert decoded.info.get('icc_profile') == original.info.get('icc_profile')
        target = Path('.tools/lossless35/png-candidates') / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        row = dict(source=path.as_posix(), sourceBytes=len(source), packedBytes=packed,
                   sourceSha256=digest(source), candidate=target.as_posix(),
                   candidateBytes=len(data), candidateSha256=digest(data),
                   savingBytes=packed-len(data), accepted=True,
                   rgbaSha256=digest(original.convert('RGBA').tobytes()),
                   dimensions=list(original.size), rgbaExact=True,
                   iccSha256=digest(original.info.get('icc_profile', b'')))
        proof = Path('.tools/lossless35/png-proofs') / (path.as_posix()+'.json')
        proof.parent.mkdir(parents=True, exist_ok=True)
        proof.write_text(json.dumps(row, indent=2), encoding='utf-8')


if __name__ == '__main__':
    prefix = 'assets/flutter_assets/'
    with zipfile.ZipFile('build/app/outputs/flutter-apk/app-release.apk') as apk:
        jobs = [(Path(e.filename[len(prefix):]), e.compress_size)
                for e in apk.infolist()
                if e.filename.startswith(prefix+'assets/images/') and e.filename.endswith('.png')]
    with ThreadPoolExecutor(max_workers=2) as executor:
        list(executor.map(optimize, jobs))
    print('PNG fallback review candidates generated:', len(jobs))
