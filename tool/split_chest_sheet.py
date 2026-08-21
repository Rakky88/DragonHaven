"""Split the transparent 3x2 DragonHaven chest sheet."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    source = Image.open(args.source).convert("RGBA")
    if source.size != (1536, 1024):
        raise ValueError(f"Expected 1536x1024, got {source.size}")
    names = ("wooden", "silver", "gold", "dragon", "mythical", "sinister")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for index, name in enumerate(names):
        column, row = index % 3, index // 3
        image = source.crop((column * 512, row * 512, (column + 1) * 512, (row + 1) * 512))
        bounds = image.getchannel("A").getbbox()
        if bounds is None:
            raise ValueError(f"Chest cell {name} is empty")
        image = image.crop(bounds)
        image.thumbnail((460, 460), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
        canvas.alpha_composite(image, ((512 - image.width) // 2, (512 - image.height) // 2))
        canvas.save(args.output_dir / f"chest_{name}.webp", "WEBP", quality=94, method=6)


if __name__ == "__main__":
    main()
