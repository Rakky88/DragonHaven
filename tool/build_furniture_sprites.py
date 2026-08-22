"""Build distortion-free runtime furniture sprites from the 4x2 atlases.

The shop catalog stores eight forms per theme in square atlas cells. Rendering
an atlas cell directly into a rectangular room slot can stretch the artwork,
so this tool trims every cell to its visible object, restores a proportional
transparent safety gutter, and exports one naturally sized WebP per item.

It also supports the cushion-art cleanup workflow: create one reference sheet
from all first atlas cells, then replace those cells from an edited 6x4 sheet.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parent.parent
ATLAS_ROOT = PROJECT_ROOT / "assets/images/furniture_atlases"
SPRITE_ROOT = PROJECT_ROOT / "assets/images/furniture"
BUILD_ROOT = PROJECT_ROOT / "build"
COLS = 4
ROWS = 2
ALPHA_THRESHOLD = 16
ATLAS_SCALE = 0.82

THEMES = (
    "aurora",
    "cherry",
    "cloud",
    "copper",
    "coral",
    "crystal",
    "dragon",
    "ember",
    "forest",
    "frost",
    "honey",
    "lavender",
    "meadow",
    "moon",
    "mushroom",
    "ocean",
    "rainbow",
    "rose",
    "sapphire",
    "starlight",
    "storm",
    "sun",
    "twilight",
    "velvet",
)

FORMS = (
    "cushion",
    "daybed",
    "planter",
    "bonsai",
    "tapestry",
    "shelf",
    "lantern",
    "orb",
)

ORIGINALS = (
    ("moss_cushion", "furniture_moss_cushion.webp"),
    ("cloud_basket", "furniture_cloud_basket.webp"),
    ("moon_fern", "furniture_moon_fern.webp"),
    ("star_bonsai", "furniture_star_bonsai.webp"),
    ("spire_map", "furniture_spire_map.webp"),
    ("moon_banner", "furniture_moon_banner.webp"),
    ("firefly_lamp", "furniture_firefly_lamp.webp"),
    ("crystal_lantern", "furniture_crystal_lantern.webp"),
)


def visible_bounds(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    mask = alpha.point(lambda value: 255 if value >= ALPHA_THRESHOLD else 0)
    bounds = mask.getbbox()
    if bounds is None:
        raise ValueError("Sprite cell contains no visible pixels")
    return bounds


def trimmed_sprite(image: Image.Image, gutter: float = 0.08) -> Image.Image:
    sprite = image.crop(visible_bounds(image))
    pad_x = max(6, round(sprite.width * gutter))
    pad_y = max(6, round(sprite.height * gutter))
    output = Image.new(
        "RGBA",
        (sprite.width + pad_x * 2, sprite.height + pad_y * 2),
        (0, 0, 0, 0),
    )
    output.alpha_composite(sprite, (pad_x, pad_y))
    return output


def atlas_cell(atlas: Image.Image, slot: int) -> Image.Image:
    width = atlas.width // COLS
    height = atlas.height // ROWS
    column = slot % COLS
    row = slot // COLS
    return atlas.crop(
        (column * width, row * height, (column + 1) * width, (row + 1) * height)
    )


def without_tiny_components(image: Image.Image, minimum_pixels: int = 80) -> Image.Image:
    """Drop isolated generator specks while retaining meaningful ornaments."""
    output = image.copy()
    alpha = output.getchannel("A")
    width, height = output.size
    values = alpha.tobytes()
    visited = bytearray(width * height)
    for start, value in enumerate(values):
        if value < ALPHA_THRESHOLD or visited[start]:
            continue
        visited[start] = 1
        queue = deque([start])
        group: list[int] = []
        while queue:
            index = queue.popleft()
            group.append(index)
            x = index % width
            y = index // width
            for next_x, next_y in (
                (x - 1, y),
                (x + 1, y),
                (x, y - 1),
                (x, y + 1),
                (x - 1, y - 1),
                (x + 1, y - 1),
                (x - 1, y + 1),
                (x + 1, y + 1),
            ):
                if not (0 <= next_x < width and 0 <= next_y < height):
                    continue
                next_index = next_y * width + next_x
                if not visited[next_index] and values[next_index] >= ALPHA_THRESHOLD:
                    visited[next_index] = 1
                    queue.append(next_index)
        if len(group) < minimum_pixels:
            for index in group:
                alpha.putpixel((index % width, index // width), 0)
    output.putalpha(alpha)
    return output


def export_runtime_sprites() -> None:
    SPRITE_ROOT.mkdir(parents=True, exist_ok=True)
    written = 0
    for theme in THEMES:
        atlas = Image.open(ATLAS_ROOT / f"{theme}.webp").convert("RGBA")
        for slot, form in enumerate(FORMS):
            sprite = trimmed_sprite(atlas_cell(atlas, slot))
            destination = SPRITE_ROOT / f"decor_{theme}_{form}.webp"
            sprite.save(destination, "WEBP", quality=94, method=4, exact=True)
            written += 1
    print(f"Exported {written} proportional runtime sprites to {SPRITE_ROOT}")


def build_cushion_reference() -> None:
    BUILD_ROOT.mkdir(parents=True, exist_ok=True)
    cell_size = 256
    sheet = Image.new("RGBA", (cell_size * 6, cell_size * 4), (0, 0, 0, 0))
    for index, theme in enumerate(THEMES):
        atlas = Image.open(ATLAS_ROOT / f"{theme}.webp").convert("RGBA")
        sprite = trimmed_sprite(atlas_cell(atlas, 0), gutter=0.03)
        sprite.thumbnail((224, 224), Image.Resampling.LANCZOS)
        cell_x = index % 6
        cell_y = index // 6
        left = cell_x * cell_size + (cell_size - sprite.width) // 2
        top = cell_y * cell_size + (cell_size - sprite.height) // 2
        sheet.alpha_composite(sprite, (left, top))
    destination = BUILD_ROOT / "cushions_with_dragons_reference.png"
    sheet.save(destination)
    print(destination)


def replace_cushion_cells(sheet_path: Path) -> None:
    sheet = Image.open(sheet_path).convert("RGBA")
    if sheet.width * 2 != sheet.height * 3:
        raise ValueError(
            f"Expected a 3:2 six-by-four sheet, received {sheet.width}x{sheet.height}"
        )
    source_width = sheet.width // 6
    source_height = sheet.height // 4
    for index, theme in enumerate(THEMES):
        column = index % 6
        row = index // 6
        source = sheet.crop(
            (
                column * source_width,
                row * source_height,
                (column + 1) * source_width,
                (row + 1) * source_height,
            )
        )
        source = without_tiny_components(source)
        source = source.crop(visible_bounds(source))

        atlas_path = ATLAS_ROOT / f"{theme}.webp"
        atlas = Image.open(atlas_path).convert("RGBA")
        cell_width = atlas.width // COLS
        cell_height = atlas.height // ROWS
        source.thumbnail(
            (
                round(cell_width * ATLAS_SCALE),
                round(cell_height * ATLAS_SCALE),
            ),
            Image.Resampling.LANCZOS,
        )
        cleared = Image.new("RGBA", (cell_width, cell_height), (0, 0, 0, 0))
        cleared.alpha_composite(
            source,
            ((cell_width - source.width) // 2, (cell_height - source.height) // 2),
        )
        atlas.paste(cleared, (0, 0))
        atlas.save(atlas_path, "WEBP", quality=94, method=4, exact=True)
    print(f"Replaced {len(THEMES)} cushion cells without changing other forms")


def split_cushion_sheet(sheet_path: Path) -> None:
    """Export the 24 sheet cells for focused background-extraction edits."""
    sheet = Image.open(sheet_path).convert("RGBA")
    if sheet.width * 2 != sheet.height * 3:
        raise ValueError(
            f"Expected a 3:2 six-by-four sheet, received {sheet.width}x{sheet.height}"
        )
    destination = BUILD_ROOT / "cushion_cells"
    destination.mkdir(parents=True, exist_ok=True)
    cell_width = sheet.width // 6
    cell_height = sheet.height // 4
    for index, theme in enumerate(THEMES):
        column = index % 6
        row = index // 6
        cell = sheet.crop(
            (
                column * cell_width,
                row * cell_height,
                (column + 1) * cell_width,
                (row + 1) * cell_height,
            )
        )
        cell.save(destination / f"{index:02d}_{theme}.png")
    print(f"Exported {len(THEMES)} cushion cells to {destination}")


def remove_checker_background(sheet_path: Path) -> None:
    """Turn an opaque neutral checkerboard connected to the edge into alpha.

    Image generation can bake its transparency preview into an otherwise good
    sprite sheet. The checker is near-neutral and bright, while the furniture
    is bounded by colored/dark outlines. Flooding only from the outer canvas
    therefore preserves white upholstery enclosed by those outlines.
    """
    image = Image.open(sheet_path).convert("RGBA")
    width, height = image.size
    pixels = image.load()
    visited = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def is_checker(x: int, y: int) -> bool:
        red, green, blue, _ = pixels[x, y]
        return min(red, green, blue) >= 226 and max(red, green, blue) - min(
            red, green, blue
        ) <= 16

    def enqueue(x: int, y: int) -> None:
        index = y * width + x
        if not visited[index] and is_checker(x, y):
            visited[index] = 1
            queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        for next_x, next_y in (
            (x - 1, y),
            (x + 1, y),
            (x, y - 1),
            (x, y + 1),
            (x - 1, y - 1),
            (x + 1, y - 1),
            (x - 1, y + 1),
            (x + 1, y + 1),
        ):
            if 0 <= next_x < width and 0 <= next_y < height:
                enqueue(next_x, next_y)

    removed = 0
    for y in range(height):
        for x in range(width):
            if visited[y * width + x]:
                red, green, blue, _ = pixels[x, y]
                pixels[x, y] = (red, green, blue, 0)
                removed += 1

    destination = BUILD_ROOT / "cushions_empty_transparent.png"
    image.save(destination)
    print(f"Removed {removed} connected checker pixels; wrote {destination}")


def build_runtime_contacts() -> None:
    """Render all 200 final assets with contain-fitting for visual QA."""
    from PIL import ImageDraw

    items = [
        (item_id, PROJECT_ROOT / "assets/images" / filename)
        for item_id, filename in ORIGINALS
    ]
    items.extend(
        (
            f"decor_{theme}_{form}",
            SPRITE_ROOT / f"decor_{theme}_{form}.webp",
        )
        for theme in THEMES
        for form in FORMS
    )
    columns = 5
    rows = 10
    tile_width = 220
    tile_height = 180
    label_height = 26
    for page_start in range(0, len(items), columns * rows):
        page_items = items[page_start : page_start + columns * rows]
        sheet = Image.new(
            "RGB",
            (columns * tile_width, rows * (tile_height + label_height)),
            "#ddd9d0",
        )
        draw = ImageDraw.Draw(sheet)
        for offset, (item_id, path) in enumerate(page_items):
            image = Image.open(path).convert("RGBA")
            image.thumbnail((190, 148), Image.Resampling.LANCZOS)
            column = offset % columns
            row = offset // columns
            left = column * tile_width
            top = row * (tile_height + label_height)
            background = "#fffaf0" if offset % 2 == 0 else "#d6e0e6"
            draw.rounded_rectangle(
                (left + 7, top + 7, left + tile_width - 7, top + tile_height - 7),
                radius=13,
                fill=background,
                outline="#716b64",
                width=2,
            )
            sheet.paste(
                image,
                (
                    left + (tile_width - image.width) // 2,
                    top + (tile_height - image.height) // 2,
                ),
                image,
            )
            draw.text((left + 8, top + tile_height + 3), item_id, fill="#171717")
        page = page_start // (columns * rows) + 1
        destination = BUILD_ROOT / f"furniture_runtime_contact_{page}.jpg"
        sheet.save(destination, quality=94)
        print(destination)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--cushion-reference",
        action="store_true",
        help="Write the 6x4 input sheet used for the no-dragons artwork edit.",
    )
    parser.add_argument(
        "--replace-cushions",
        type=Path,
        help="Replace atlas cushion cells from a transparent 6x4 edited sheet.",
    )
    parser.add_argument(
        "--split-cushions",
        type=Path,
        help="Split a six-by-four cushion sheet into 24 focused edit inputs.",
    )
    parser.add_argument(
        "--remove-checker",
        type=Path,
        help="Extract genuine alpha from a baked neutral checkerboard sheet.",
    )
    parser.add_argument(
        "--runtime-contacts",
        action="store_true",
        help="Render all 200 final sprites on four proportional QA sheets.",
    )
    args = parser.parse_args()
    if args.cushion_reference:
        build_cushion_reference()
    elif args.runtime_contacts:
        build_runtime_contacts()
    elif args.remove_checker:
        remove_checker_background(args.remove_checker)
    elif args.split_cushions:
        split_cushion_sheet(args.split_cushions)
    elif args.replace_cushions:
        replace_cushion_cells(args.replace_cushions)
        export_runtime_sprites()
    else:
        export_runtime_sprites()


if __name__ == "__main__":
    main()
