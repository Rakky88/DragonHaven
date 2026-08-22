"""Remove baked generator backgrounds and foreign fragments from dragon art.

Each logical dragon form must be one isolated subject on alpha. Some generated
source sheets left white/checker fragments or pieces of a neighbouring form in
the nominal cell. This tool keeps the complete largest alpha component, clears
bright neutral background connected to its outer edge, and recenters the
natural-aspect subject with a safe transparent gutter.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

from repack_furniture_atlases import ALPHA_THRESHOLD, components


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DRAGON_ROOT = PROJECT_ROOT / "assets/images/dragons"
OUTPUT_SIZE = 512
MAX_SUBJECT_SIZE = 452


def largest_component_cutout(cell: Image.Image) -> tuple[Image.Image, int]:
    rgba = cell.convert("RGBA")
    isolated, removed = keep_largest_component(rgba)
    isolated = clear_edge_neutral_background(isolated)
    isolated, second_removed = keep_largest_component(isolated)
    removed += second_removed
    bounds = isolated.getchannel("A").point(
        lambda value: 255 if value >= 8 else 0
    ).getbbox()
    if bounds is None:
        raise ValueError("Dragon frame became empty during cleanup")
    isolated = isolated.crop(bounds)
    isolated.thumbnail(
        (MAX_SUBJECT_SIZE, MAX_SUBJECT_SIZE), Image.Resampling.LANCZOS
    )
    canvas = Image.new("RGBA", (OUTPUT_SIZE, OUTPUT_SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(
        isolated,
        ((OUTPUT_SIZE - isolated.width) // 2, (OUTPUT_SIZE - isolated.height) // 2),
    )
    return canvas, removed


def keep_largest_component(rgba: Image.Image) -> tuple[Image.Image, int]:
    alpha = rgba.getchannel("A")
    found = components(alpha)
    if not found:
        raise ValueError("Dragon frame contains no alpha component")
    found.sort(key=lambda component: len(component[0]), reverse=True)
    keep = found[0]
    mask_data = bytearray(rgba.width * rgba.height)
    for index in keep[0]:
        mask_data[index] = 255
    mask = Image.frombytes("L", rgba.size, bytes(mask_data)).filter(
        ImageFilter.MaxFilter(3)
    )
    isolated_alpha = ImageChops.multiply(alpha, mask)
    isolated = rgba.copy()
    isolated.putalpha(isolated_alpha)
    return isolated, max(0, len(found) - 1)


def clear_edge_neutral_background(image: Image.Image) -> Image.Image:
    """Remove bright neutral matte connected to transparent surroundings."""
    output = image.copy()
    width, height = output.size
    pixels = output.load()
    visited = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def candidate(x: int, y: int) -> bool:
        red, green, blue, alpha = pixels[x, y]
        return (
            alpha >= 8
            and min(red, green, blue) >= 205
            and max(red, green, blue) - min(red, green, blue) <= 24
        )

    def touches_transparency(x: int, y: int) -> bool:
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
                return True
            if pixels[next_x, next_y][3] < 8:
                return True
        return False

    for y in range(height):
        for x in range(width):
            if candidate(x, y) and touches_transparency(x, y):
                index = y * width + x
                if not visited[index]:
                    visited[index] = 1
                    queue.append((x, y))

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
            if not (0 <= next_x < width and 0 <= next_y < height):
                continue
            index = next_y * width + next_x
            if not visited[index] and candidate(next_x, next_y):
                visited[index] = 1
                queue.append((next_x, next_y))

    alpha = output.getchannel("A")
    for index, marked in enumerate(visited):
        if marked:
            alpha.putpixel((index % width, index // width), 0)
    output.putalpha(alpha)
    return output


def clean_hatchling(source: Path, destination: Path) -> int:
    image = Image.open(source).convert("RGBA")
    clean, removed = largest_component_cutout(image)
    clean.save(destination, "WEBP", quality=94, method=4, exact=True)
    return removed


def clean_forms(source: Path, destination: Path) -> int:
    image = Image.open(source).convert("RGBA")
    output = Image.new("RGBA", (OUTPUT_SIZE * 2, OUTPUT_SIZE * 2), (0, 0, 0, 0))
    removed = 0
    for slot in range(4):
        column = slot % 2
        row = slot // 2
        left = round(column * image.width / 2)
        right = round((column + 1) * image.width / 2)
        top = round(row * image.height / 2)
        bottom = round((row + 1) * image.height / 2)
        clean, frame_removed = largest_component_cutout(
            image.crop((left, top, right, bottom))
        )
        removed += frame_removed
        output.alpha_composite(clean, (column * OUTPUT_SIZE, row * OUTPUT_SIZE))
    output.save(destination, "WEBP", quality=94, method=4, exact=True)
    return removed


def preview(family: str) -> None:
    destination = PROJECT_ROOT / "build/dragon_cleanup_preview"
    destination.mkdir(parents=True, exist_ok=True)
    hatchling = DRAGON_ROOT / f"{family}_hatchling.webp"
    forms = DRAGON_ROOT / f"{family}_forms.webp"
    clean_hatchling(hatchling, destination / hatchling.name)
    clean_forms(forms, destination / forms.name)
    print(destination)


def clean_all() -> None:
    files = sorted(DRAGON_ROOT.glob("*_hatchling.webp"))
    forms = sorted(DRAGON_ROOT.glob("*_forms.webp"))
    if len(files) != 43 or len(forms) != 43:
        raise RuntimeError(
            f"Expected 43 Hatchlings and 43 form atlases, got {len(files)} and {len(forms)}"
        )
    removed = 0
    for path in files:
        removed += clean_hatchling(path, path)
    for path in forms:
        removed += clean_forms(path, path)
    print(
        f"Cleaned {len(files)} Hatchlings and {len(forms) * 4} form frames; "
        f"removed {removed} foreign alpha components"
    )


def build_contacts() -> None:
    """Render all 215 cleaned dragon forms for visual inspection."""
    from PIL import ImageDraw

    hatchlings = sorted(DRAGON_ROOT.glob("*_hatchling.webp"))
    families_per_page = 9
    tile = 180
    label_height = 24
    build_root = PROJECT_ROOT / "build"
    for page_start in range(0, len(hatchlings), families_per_page):
        page_families = hatchlings[page_start : page_start + families_per_page]
        sheet = Image.new(
            "RGB",
            (tile * 5, (tile + label_height) * len(page_families)),
            "#d9d7d0",
        )
        draw = ImageDraw.Draw(sheet)
        for row, hatchling_path in enumerate(page_families):
            family = hatchling_path.stem.removesuffix("_hatchling")
            forms = Image.open(DRAGON_ROOT / f"{family}_forms.webp").convert("RGBA")
            images = [Image.open(hatchling_path).convert("RGBA")]
            images.extend(
                forms.crop(
                    (
                        (slot % 2) * OUTPUT_SIZE,
                        (slot // 2) * OUTPUT_SIZE,
                        (slot % 2 + 1) * OUTPUT_SIZE,
                        (slot // 2 + 1) * OUTPUT_SIZE,
                    )
                )
                for slot in range(4)
            )
            for column, image in enumerate(images):
                image.thumbnail((164, 164), Image.Resampling.LANCZOS)
                left = column * tile
                top = row * (tile + label_height)
                background = "#fffaf0" if (row + column) % 2 == 0 else "#cad7df"
                draw.rounded_rectangle(
                    (left + 5, top + 5, left + tile - 5, top + tile - 5),
                    radius=12,
                    fill=background,
                    outline="#67615b",
                    width=2,
                )
                sheet.paste(
                    image,
                    (
                        left + (tile - image.width) // 2,
                        top + (tile - image.height) // 2,
                    ),
                    image,
                )
            draw.text(
                (8, row * (tile + label_height) + tile + 3),
                f"{family}: Hatchling | Wyrmling | Might | Arcana | Spirit",
                fill="#171717",
            )
        page = page_start // families_per_page + 1
        destination = build_root / f"dragon_runtime_contact_{page}.jpg"
        sheet.save(destination, quality=94)
        print(destination)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--preview", help="Clean one family into build only.")
    parser.add_argument(
        "--contacts",
        action="store_true",
        help="Render all cleaned dragon forms on five QA contact sheets.",
    )
    args = parser.parse_args()
    if args.preview:
        preview(args.preview)
    elif args.contacts:
        build_contacts()
    else:
        clean_all()


if __name__ == "__main__":
    main()
