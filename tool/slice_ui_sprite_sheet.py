"""Split a white-matted generated UI sheet into transparent app sprites."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def remove_white_matte(image: Image.Image) -> Image.Image:
    """Recover a useful alpha channel from artwork rendered on solid white."""

    rgba = image.convert("RGBA")
    pixels = []
    for red, green, blue, _ in rgba.getdata():
        distance = max(255 - red, 255 - green, 255 - blue)
        alpha = max(0, min(255, round((distance - 4) * 255 / 30)))
        if alpha == 0:
            pixels.append((0, 0, 0, 0))
            continue
        factor = 255 / alpha
        pixels.append(
            (
                max(0, min(255, round(255 + (red - 255) * factor))),
                max(0, min(255, round(255 + (green - 255) * factor))),
                max(0, min(255, round(255 + (blue - 255) * factor))),
                alpha,
            )
        )
    rgba.putdata(pixels)
    return rgba


def prepare_cell(
    cell: Image.Image,
    destination: Path,
    *,
    max_edge: int,
    gutter: float,
) -> None:
    transparent = remove_white_matte(cell)
    bounds = transparent.getchannel("A").point(lambda value: 255 if value > 8 else 0).getbbox()
    if bounds is None:
        raise ValueError(f"Generated cell is empty: {destination.name}")
    sprite = transparent.crop(bounds)
    content_edge = max(1, round(max_edge * (1 - gutter * 2)))
    sprite.thumbnail((content_edge, content_edge), Image.Resampling.LANCZOS)
    output = Image.new("RGBA", (max_edge, max_edge), (0, 0, 0, 0))
    output.alpha_composite(
        sprite,
        ((max_edge - sprite.width) // 2, (max_edge - sprite.height) // 2),
    )
    destination.parent.mkdir(parents=True, exist_ok=True)
    output.save(destination, "WEBP", quality=94, method=6, exact=True)
    print(f"{destination}: {output.width}x{output.height}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("names", nargs="+")
    parser.add_argument("--columns", type=int, required=True)
    parser.add_argument("--rows", type=int, required=True)
    parser.add_argument("--max-edge", type=int, default=512)
    parser.add_argument("--gutter", type=float, default=0.06)
    args = parser.parse_args()
    if len(args.names) != args.columns * args.rows:
        raise ValueError("The number of names must match columns x rows")

    sheet = Image.open(args.source).convert("RGB")
    for index, name in enumerate(args.names):
        column = index % args.columns
        row = index // args.columns
        left = round(column * sheet.width / args.columns)
        right = round((column + 1) * sheet.width / args.columns)
        top = round(row * sheet.height / args.rows)
        bottom = round((row + 1) * sheet.height / args.rows)
        prepare_cell(
            sheet.crop((left, top, right, bottom)),
            args.destination / f"{name}.webp",
            max_edge=args.max_edge,
            gutter=args.gutter,
        )


if __name__ == "__main__":
    main()
