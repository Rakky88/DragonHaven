"""Crop an image-generator scene to a deterministic app asset size."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageOps


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("width", type=int)
    parser.add_argument("height", type=int)
    args = parser.parse_args()

    source = Image.open(args.source).convert("RGB")
    prepared = ImageOps.fit(
        source,
        (args.width, args.height),
        method=Image.Resampling.LANCZOS,
        centering=(0.5, 0.5),
    )
    args.destination.parent.mkdir(parents=True, exist_ok=True)
    prepared.save(args.destination, "WEBP", quality=92, method=6)


if __name__ == "__main__":
    main()
