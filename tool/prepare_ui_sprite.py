"""Prepare generated UI art as compact, naturally proportioned app sprites."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


ALPHA_THRESHOLD = 8


def prepare(source: Path, destination: Path, max_edge: int, gutter: float) -> None:
    image = Image.open(source).convert("RGBA")
    mask = image.getchannel("A").point(
        lambda value: 255 if value >= ALPHA_THRESHOLD else 0
    )
    bounds = mask.getbbox()
    if bounds is None:
        raise ValueError(f"Generated sprite is empty: {source}")
    sprite = image.crop(bounds)
    content_edge = max(1, round(max_edge * (1 - gutter * 2)))
    sprite.thumbnail((content_edge, content_edge), Image.Resampling.LANCZOS)
    pad = max(4, round(max(sprite.width, sprite.height) * gutter))
    output = Image.new(
        "RGBA",
        (sprite.width + pad * 2, sprite.height + pad * 2),
        (0, 0, 0, 0),
    )
    output.alpha_composite(sprite, (pad, pad))
    destination.parent.mkdir(parents=True, exist_ok=True)
    output.save(destination, "WEBP", quality=94, method=6, exact=True)
    print(f"{destination}: {output.width}x{output.height}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--max-edge", type=int, default=512)
    parser.add_argument("--gutter", type=float, default=0.06)
    args = parser.parse_args()
    if args.max_edge < 64 or args.max_edge > 2048:
        raise ValueError("max-edge must be between 64 and 2048")
    if not 0 <= args.gutter <= 0.25:
        raise ValueError("gutter must be between 0 and 0.25")
    prepare(args.source, args.destination, args.max_edge, args.gutter)


if __name__ == "__main__":
    main()
