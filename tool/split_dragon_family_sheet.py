"""Split a transparent 1536x1024 five-form sheet into app sprite assets."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def fitted_cell(source: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    crop = source.crop(box)
    alpha = crop.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError(f"No visible sprite pixels in {box}")
    crop = crop.crop(bounds)
    crop.thumbnail((470, 470), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    canvas.alpha_composite(crop, ((512 - crop.width) // 2, (512 - crop.height) // 2))
    return canvas


def split(source_path: Path, family_id: str, output_dir: Path) -> None:
    source = Image.open(source_path).convert("RGBA")
    if source.size != (1536, 1024):
        raise ValueError(f"Expected 1536x1024 sheet, received {source.size}")
    # The generator consistently reserves three top cells and two wide bottom
    # zones. Bounding-box fitting then gives every form equal safe padding.
    hatchling = fitted_cell(source, (0, 0, 512, 512))
    wyrmling = fitted_cell(source, (512, 0, 1024, 512))
    might = fitted_cell(source, (1024, 0, 1536, 512))
    arcana = fitted_cell(source, (0, 512, 768, 1024))
    spirit = fitted_cell(source, (768, 512, 1536, 1024))

    output_dir.mkdir(parents=True, exist_ok=True)
    hatchling.save(output_dir / f"{family_id}_hatchling.webp", "WEBP", quality=94, method=6)
    atlas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    atlas.alpha_composite(wyrmling, (0, 0))
    atlas.alpha_composite(might, (512, 0))
    atlas.alpha_composite(arcana, (0, 512))
    atlas.alpha_composite(spirit, (512, 512))
    atlas.save(output_dir / f"{family_id}_forms.webp", "WEBP", quality=94, method=6)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("family_id")
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    split(args.source, args.family_id, args.output_dir)


if __name__ == "__main__":
    main()
