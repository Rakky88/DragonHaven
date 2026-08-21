"""Convert DragonHaven's large in-game PNG artwork to transparent WebP assets."""

from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parent.parent


def convert(source: Path, quality: int) -> tuple[int, int]:
    image = Image.open(source)
    output = source.with_suffix(".webp")
    original_size = source.stat().st_size
    image.save(output, "WEBP", quality=quality, method=6, exact=True)
    with Image.open(output) as validated:
        if validated.size != image.size:
            raise RuntimeError(f"Dimension mismatch for {source}")
        if "A" in image.getbands() and "A" not in validated.getbands():
            raise RuntimeError(f"Alpha channel lost for {source}")
    return original_size, output.stat().st_size


def main() -> None:
    transparent = [
        *(PROJECT_ROOT / "assets/images/dragons").glob("*.png"),
        *(PROJECT_ROOT / "assets/images/furniture_atlases").glob("*.png"),
        *(PROJECT_ROOT / "assets/images").glob("furniture_*.png"),
    ]
    backgrounds = [
        PROJECT_ROOT / "assets/images/tower_nest.png",
        *(PROJECT_ROOT / "assets/images").glob("house_room_*.png"),
    ]
    sources = [(path, 92) for path in transparent]
    sources.extend((path, 90) for path in backgrounds)
    sources = sorted(set(sources), key=lambda entry: str(entry[0]))

    total_before = 0
    total_after = 0
    for source, quality in sources:
        before, after = convert(source, quality)
        total_before += before
        total_after += after
        print(f"{source.relative_to(PROJECT_ROOT)}: {before} -> {after}")
    print(f"TOTAL: {total_before} -> {total_after} bytes")


if __name__ == "__main__":
    main()
