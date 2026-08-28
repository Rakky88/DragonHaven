"""Import the reviewed CC0/Public Domain DragonHaven jukebox sources.

The large PDMX download and transient external downloads stay under ``.tmp``.
Only the compact MIDI/Ogg resources and their generated source manifest ship.
"""

from __future__ import annotations

import csv
import re
import shutil
import tarfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PDMX = ROOT / ".tmp" / "pdmx"
REPORT = PDMX / "candidates_cc0_pd.txt"
RAW = ROOT / "android" / "app" / "src" / "main" / "res" / "raw"
EXTERNAL = ROOT / ".tmp" / "music_external"
MANIFEST = ROOT / "assets" / "licenses" / "MUSIC_SOURCES.md"

# Reviewed corrections to the automatic candidate ranking. Values are PDMX
# row numbers, not mutable titles.
ROW_OVERRIDES = {
    "reverie": 3805,
    "gymnopedie_3": 48083,
    "moonlight_3": 73170,
    "lacrimosa": 79998,
    "winter_2": 179436,
    "funeral_march": 234381,
    "hungarian_dance_6": None,
    "lullaby": 134153,
    "tritsch_tratsch": None,
    "scheherazade_prince_princess": None,
    "elite_syncopations": None,
    "auld_lang_syne": 12857,
    "golliwoggs_cakewalk": None,
    "gymnopedie_2": None,
    "autumn_1": None,
}

EXTERNAL_SOURCES = {
    "elite_syncopations": {
        "title": "Elite Syncopations",
        "license": "Public Domain",
        "page": "https://www.mutopiaproject.org/cgibin/piece-info.cgi?id=1540",
        "note": "Mutopia MIDI based on the Public Domain John Stark & Son edition",
    },
    "golliwoggs_cakewalk": {
        "title": "Golliwogg's Cake-Walk",
        "license": "Public Domain",
        "page": "https://art-translator.com/collection/210",
        "note": "Sergei Rachmaninoff, 1921 Victor/Victrola 78rpm; Great 78 Project",
    },
    "gymnopedie_2": {
        "title": "Gymnopédie No. 2",
        "license": "Public Domain",
        "page": "https://www.ibiblio.org/mutopia/cgibin/piece-info.cgi?id=38",
        "note": "Mutopia MIDI based on the Public Domain Dover edition",
    },
    "autumn_1": {
        "title": "Autumn – I",
        "license": "Public Domain Mark",
        "page": "https://commons.wikimedia.org/wiki/File:The_Modena_Chamber_Orchestra_-_Vivaldi%27s_Autumn,_RV_293_-_I._Allegro.ogg",
        "note": "The Modena Chamber Orchestra; Musopen recording",
    },
    "hungarian_dance_6": {
        "title": "Hungarian Dance No. 6",
        "license": "Public Domain Mark",
        "page": "https://commons.wikimedia.org/wiki/File:Brahms_nikisch_hd6.ogg",
        "note": "Artur Nikisch, 1906 Welte-Mignon reproducing piano",
    },
    "scheherazade_prince_princess": {
        "title": "Scheherazade – Young Prince and Princess",
        "license": "CC0 1.0",
        "page": "https://commons.wikimedia.org/wiki/File:Rimsky-Korsakov._Scheherazade,_Symphonic_Suite,_Op._35_-_03_The_Young_Prince_And_Princess.ogg",
        "note": "San Francisco Symphony Orchestra, Pierre Monteux, 1942",
    },
    "tritsch_tratsch": {
        "title": "Tritsch-Tratsch-Polka",
        "license": "Public Domain Mark",
        "page": "https://commons.wikimedia.org/wiki/File:Johann_Strauss_Jr_%C2%ABTritsch-Tratsch-Polka%C2%BB_trascrizione_per_pianoforte.ogg",
        "note": "Historic piano-roll transcription performed by S. Ventura",
    },
}


def report_paths() -> dict[str, str]:
    selected: dict[str, str] = {}
    current: str | None = None
    for line in REPORT.read_text(encoding="utf-8").splitlines():
        if line.startswith("## "):
            current = line[3:].split(":", 1)[0]
        elif current and line.startswith("score=") and current not in selected:
            selected[current] = re.search(r"mid=(.+\.mid)$", line).group(1)
    return selected


def metadata_by_row(rows: set[int]) -> dict[int, dict[str, str]]:
    found: dict[int, dict[str, str]] = {}
    with (PDMX / "PDMX.csv").open(encoding="utf-8", newline="") as source:
        for row_number, row in enumerate(csv.DictReader(source), start=2):
            if row_number in rows:
                found[row_number] = row
                if len(found) == len(rows):
                    break
    return found


def main() -> None:
    auto = report_paths()
    wanted_ids = set(auto) | set(ROW_OVERRIDES)
    selected_paths = {
        track_id: path
        for track_id, path in auto.items()
        if ROW_OVERRIDES.get(track_id, -1) is not None
    }

    override_rows = {row for row in ROW_OVERRIDES.values() if row is not None}
    rows = metadata_by_row(override_rows)
    for track_id, row_number in ROW_OVERRIDES.items():
        if row_number is not None:
            selected_paths[track_id] = rows[row_number]["mid"]

    metadata_rows: dict[str, dict[str, str]] = {}
    path_to_id = {path: track_id for track_id, path in selected_paths.items()}
    with (PDMX / "PDMX.csv").open(encoding="utf-8", newline="") as source:
        for row_number, row in enumerate(csv.DictReader(source), start=2):
            track_id = path_to_id.get(row["mid"])
            if track_id is not None:
                row["_row_number"] = str(row_number)
                metadata_rows[track_id] = row
                if len(metadata_rows) == len(selected_paths):
                    break

    if set(metadata_rows) != set(selected_paths):
        raise RuntimeError("Not every reviewed PDMX source was found in PDMX.csv")
    if any(row["license"] not in {"cc-zero", "publicdomain"} for row in metadata_rows.values()):
        raise RuntimeError("A selected PDMX source is not explicitly CC0/Public Domain")
    invalid_subsets = [
        track_id
        for track_id, row in metadata_rows.items()
        if row["subset:no_license_conflict"] != "True"
        or row["license_conflict"] != "False"
        or row["subset:all_valid"] != "True"
    ]
    if invalid_subsets:
        raise RuntimeError(
            "Conflicted or invalid PDMX selections: "
            + ", ".join(sorted(invalid_subsets))
        )

    RAW.mkdir(parents=True, exist_ok=True)
    for existing in RAW.glob("music_*"):
        existing.unlink()
    with tarfile.open(PDMX / "mid.tar.gz", "r:gz") as archive:
        members = {member.name: member for member in archive if member.isfile()}
        for track_id, source_path in selected_paths.items():
            archive_name = source_path.removeprefix("./")
            member = members.get(archive_name)
            if member is None:
                raise RuntimeError(f"Missing {archive_name} in PDMX MIDI archive")
            source = archive.extractfile(member)
            assert source is not None
            (RAW / f"music_{track_id}.mid").write_bytes(source.read())

    for track_id in EXTERNAL_SOURCES:
        matches = list(EXTERNAL.glob(f"{track_id}.*"))
        if len(matches) != 1:
            raise RuntimeError(f"Expected one reviewed external file for {track_id}")
        shutil.copyfile(matches[0], RAW / f"music_{track_id}{matches[0].suffix.lower()}")

    if wanted_ids != set(metadata_rows) | set(EXTERNAL_SOURCES):
        missing = wanted_ids - set(metadata_rows) - set(EXTERNAL_SOURCES)
        raise RuntimeError(f"Unresolved music IDs: {sorted(missing)}")

    lines = [
        "# DragonHaven music sources",
        "",
        "Every shipped jukebox resource is an explicitly CC0 or Public Domain",
        "MIDI/performance source. The composition title alone was not treated as",
        "sufficient clearance for a modern recording.",
        "",
        "PDMX dataset: https://zenodo.org/records/15571083",
        "",
        "| Resource | Source title | Composer/artist | License | Source |",
        "|---|---|---|---|---|",
    ]
    for track_id in sorted(metadata_rows):
        row = metadata_rows[track_id]
        title = (row["title"] or row["song_name"]).replace("|", "\\|")
        creator = (row["composer_name"] or row["artist_name"]).replace("|", "\\|")
        license_name = "CC0 1.0" if row["license"] == "cc-zero" else "Public Domain Mark"
        lines.append(
            f"| `music_{track_id}` | {title} | {creator} | {license_name} | "
            f"PDMX row {row['_row_number']} |"
        )
    for track_id, source in sorted(EXTERNAL_SOURCES.items()):
        lines.append(
            f"| `music_{track_id}` | {source['title']} | {source['note']} | "
            f"{source['license']} | [source page]({source['page']}) |"
        )
    lines.extend(
        [
            "",
            "PDMX row licenses were checked from `PDMX.csv`; every selected row",
            "is in both the `no_license_conflict` and `all_valid` subsets and uses",
            "`https://creativecommons.org/publicdomain/zero/1.0/` or",
            "`https://creativecommons.org/publicdomain/mark/1.0/`.",
            "",
        ]
    )
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST.write_text("\n".join(lines), encoding="utf-8")


if __name__ == "__main__":
    main()
