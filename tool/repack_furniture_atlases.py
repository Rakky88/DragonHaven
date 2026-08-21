"""Repack generated furniture atlases into eight isolated sprite cells.

The image generator occasionally lets a dragon tail or blanket cross a grid
line. This script labels transparent-image components on a small mask, assigns
each complete component to its intended grid position, and scales the complete
object back into a cell with a safe gutter.
"""

from collections import deque
from pathlib import Path
import sys

from PIL import Image, ImageChops, ImageFilter


PROJECT_ROOT = Path(__file__).resolve().parent.parent
SOURCE_ROOT = PROJECT_ROOT / "artwork_sources/png_originals/furniture_atlases"
OUTPUT_ROOT = PROJECT_ROOT / "assets/images/furniture_atlases"
COLS = 4
ROWS = 2
MASK_SCALE = 2
ALPHA_THRESHOLD = 24
TARGET_SCALE = 0.84


def components(
    mask: Image.Image,
) -> list[tuple[list[int], float, float, int, int, int, int]]:
    width, height = mask.size
    active = mask.tobytes()
    visited = bytearray(width * height)
    found: list[tuple[list[int], float, float, int, int, int, int]] = []
    for start, value in enumerate(active):
        if value < ALPHA_THRESHOLD or visited[start]:
            continue
        queue = deque([start])
        visited[start] = 1
        indices: list[int] = []
        sum_x = 0
        sum_y = 0
        min_x = width
        min_y = height
        max_x = 0
        max_y = 0
        while queue:
            index = queue.popleft()
            indices.append(index)
            x = index % width
            y = index // width
            sum_x += x
            sum_y += y
            min_x = min(min_x, x)
            min_y = min(min_y, y)
            max_x = max(max_x, x)
            max_y = max(max_y, y)
            for neighbor in (
                index - width - 1,
                index - width,
                index - width + 1,
                index - 1,
                index + 1,
                index + width - 1,
                index + width,
                index + width + 1,
            ):
                if neighbor < 0 or neighbor >= width * height:
                    continue
                neighbor_x = neighbor % width
                if abs(neighbor_x - x) > 1:
                    continue
                if not visited[neighbor] and active[neighbor] >= ALPHA_THRESHOLD:
                    visited[neighbor] = 1
                    queue.append(neighbor)
        if len(indices) >= 3:
            found.append(
                (
                    indices,
                    sum_x / len(indices),
                    sum_y / len(indices),
                    min_x,
                    min_y,
                    max_x,
                    max_y,
                )
            )
    return found


def repack(source_path: Path) -> None:
    source = Image.open(source_path).convert("RGBA")
    width, height = source.size
    small_size = (width // MASK_SCALE, height // MASK_SCALE)
    small_alpha = source.getchannel("A").resize(small_size, Image.Resampling.BOX)
    groups: list[list[int]] = [[] for _ in range(COLS * ROWS)]
    found = components(small_alpha)
    seeds = []
    for slot in range(COLS * ROWS):
        column = slot % COLS
        row = slot // COLS
        candidates = [
            component
            for component in found
            if int(component[1] * COLS / small_size[0]) == column
            and int(component[2] * ROWS / small_size[1]) == row
        ]
        if not candidates:
            raise RuntimeError(
                f"No central sprite component in {source_path.name} slot {slot}"
            )
        seeds.append(max(candidates, key=lambda component: len(component[0])))

    # Generated atlases can contain a disconnected sliver of a neighboring
    # object just across a nominal cell boundary. Keep only the complete main
    # connected object for every slot. Losing an occasional loose sparkle is
    # preferable to showing a foreign bedpost, wing, branch, or tail in-game.
    for slot, seed in enumerate(seeds):
        groups[slot].extend(seed[0])

    output = Image.new("RGBA", source.size)
    cell_width = width / COLS
    cell_height = height / ROWS
    for slot, indices in enumerate(groups):
        if not indices:
            raise RuntimeError(f"No sprite found in {source_path.name} slot {slot}")
        mask_data = bytearray(small_size[0] * small_size[1])
        for index in indices:
            mask_data[index] = 255
        component_mask = Image.frombytes("L", small_size, bytes(mask_data))
        component_mask = component_mask.filter(ImageFilter.MaxFilter(5)).resize(
            source.size, Image.Resampling.NEAREST
        )
        alpha = ImageChops.multiply(source.getchannel("A"), component_mask)
        bounds = alpha.getbbox()
        if bounds is None:
            raise RuntimeError(f"Empty sprite in {source_path.name} slot {slot}")
        isolated = source.copy()
        isolated.putalpha(alpha)
        isolated = isolated.crop(bounds)
        scale = min(
            cell_width * TARGET_SCALE / isolated.width,
            cell_height * TARGET_SCALE / isolated.height,
        )
        target_size = (
            max(1, round(isolated.width * scale)),
            max(1, round(isolated.height * scale)),
        )
        isolated = isolated.resize(target_size, Image.Resampling.LANCZOS)
        column = slot % COLS
        row = slot // COLS
        left = round(column * cell_width + (cell_width - target_size[0]) / 2)
        top = round(row * cell_height + (cell_height - target_size[1]) / 2)
        output.alpha_composite(isolated, (left, top))

    destination = OUTPUT_ROOT / f"{source_path.stem}.webp"
    output.save(destination, "WEBP", quality=92, method=4, exact=True)
    print(destination.relative_to(PROJECT_ROOT))


def main() -> None:
    sources = sorted(SOURCE_ROOT.glob("*.png"))
    if len(sources) != 24:
        raise RuntimeError(f"Expected 24 source atlases, found {len(sources)}")
    for source in sources:
        repack(source)


def contact_sheet() -> None:
    files = sorted(OUTPUT_ROOT.glob("*.webp"))
    tile_width, tile_height = 400, 200
    sheet = Image.new("RGB", (tile_width * 4, (tile_height + 28) * 6), "white")
    from PIL import ImageDraw

    draw = ImageDraw.Draw(sheet)
    for index, path in enumerate(files):
        image = Image.open(path).convert("RGBA")
        image.thumbnail((tile_width, tile_height), Image.Resampling.LANCZOS)
        left = (index % 4) * tile_width
        top = (index // 4) * (tile_height + 28)
        sheet.paste(image, (left, top), image)
        draw.text((left + 5, top + 204), path.stem, fill="black")
    destination = PROJECT_ROOT / "build/furniture_contact_sheet_repacked.jpg"
    sheet.save(destination, quality=92)
    print(destination)


def contact_cells() -> None:
    """Render every runtime cell with a visible gutter for visual QA."""
    from PIL import ImageDraw

    files = sorted(OUTPUT_ROOT.glob("*.webp"))
    frame_width = 180
    frame_height = 180
    gutter = 14
    label_height = 28
    themes_per_page = 6
    for page_index in range(0, len(files), themes_per_page):
        page_files = files[page_index : page_index + themes_per_page]
        sheet_width = gutter + COLS * (frame_width + gutter)
        theme_height = label_height + ROWS * (frame_height + gutter)
        sheet_height = gutter + len(page_files) * theme_height
        sheet = Image.new("RGB", (sheet_width, sheet_height), "#dedbd2")
        draw = ImageDraw.Draw(sheet)
        for theme_offset, path in enumerate(page_files):
            source = Image.open(path).convert("RGBA")
            source_width, source_height = source.size
            source_cell_width = source_width // COLS
            source_cell_height = source_height // ROWS
            theme_top = gutter + theme_offset * theme_height
            draw.text((gutter, theme_top), path.stem, fill="#171717")
            for slot in range(COLS * ROWS):
                column = slot % COLS
                row = slot // COLS
                left = column * source_cell_width
                top = row * source_cell_height
                cell = source.crop(
                    (
                        left,
                        top,
                        left + source_cell_width,
                        top + source_cell_height,
                    )
                )
                cell.thumbnail((frame_width, frame_height), Image.Resampling.LANCZOS)
                target_left = gutter + column * (frame_width + gutter)
                target_top = theme_top + label_height + row * (frame_height + gutter)
                background = "#f8f5ec" if slot % 2 == 0 else "#c8d2d8"
                draw.rounded_rectangle(
                    (
                        target_left,
                        target_top,
                        target_left + frame_width,
                        target_top + frame_height,
                    ),
                    radius=12,
                    fill=background,
                    outline="#706b65",
                    width=2,
                )
                paste_left = target_left + (frame_width - cell.width) // 2
                paste_top = target_top + (frame_height - cell.height) // 2
                sheet.paste(cell, (paste_left, paste_top), cell)
        page_number = page_index // themes_per_page + 1
        destination = PROJECT_ROOT / f"build/furniture_contact_cells_{page_number}.jpg"
        sheet.save(destination, quality=94)
        print(destination)


if __name__ == "__main__":
    if sys.argv[1:] == ["--contact-sheet"]:
        contact_sheet()
    elif sys.argv[1:] == ["--contact-cells"]:
        contact_cells()
    else:
        main()
