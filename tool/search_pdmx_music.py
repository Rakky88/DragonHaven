"""Search PDMX metadata while reviewing public-domain jukebox sources."""

from __future__ import annotations

import argparse
import csv
import re
import unicodedata
from pathlib import Path


def norm(value: str) -> str:
    value = unicodedata.normalize("NFKD", value or "")
    value = "".join(ch for ch in value if not unicodedata.combining(ch))
    return " ".join(re.findall(r"[a-z0-9]+", value.casefold()))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("csv", type=Path)
    parser.add_argument("terms", nargs="+")
    parser.add_argument("--public-domain", action="store_true")
    parser.add_argument("--any", action="store_true")
    args = parser.parse_args()
    terms = [norm(term) for term in args.terms]
    with args.csv.open(encoding="utf-8", newline="") as source:
        for row_number, row in enumerate(csv.DictReader(source), start=2):
            if args.public_domain and row["license"] not in {
                "publicdomain",
                "cc-zero",
            }:
                continue
            haystack = norm(
                " ".join(
                    (
                        row["song_name"],
                        row["title"],
                        row["subtitle"],
                        row["composer_name"],
                    )
                )
            )
            matches = any(term in haystack for term in terms) if args.any else all(
                term in haystack for term in terms
            )
            if not matches:
                continue
            print(
                "\t".join(
                    (
                        f"row={row_number}",
                        f"song={row['song_name']!r}",
                        f"title={row['title']!r}",
                        f"composer={row['composer_name']!r}",
                        f"license={row['license']}",
                        f"conflict={row['license_conflict']}",
                        f"valid={row['subset:all_valid']}",
                        f"seconds={row['song_length.seconds']}",
                        f"views={row['n_views']}",
                        f"rating={row['rating']}",
                        f"mid={row['mid']}",
                    )
                )
            )


if __name__ == "__main__":
    main()
