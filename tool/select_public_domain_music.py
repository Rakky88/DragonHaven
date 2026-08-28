"""Select high-confidence public-domain MIDI candidates from PDMX.

This developer tool deliberately accepts only PDMX rows in the
``no_license_conflict`` and ``all_valid`` subsets. It writes no files; its
ranked output is intended for review before importing a compact set of MIDI
resources into the Android app.
"""

from __future__ import annotations

import argparse
import csv
import heapq
import re
import unicodedata
from difflib import SequenceMatcher
from pathlib import Path


TRACKS = [
    ("clair_de_lune", "Clair de Lune", "Debussy"),
    ("arabesque_1", "Arabesque No. 1", "Debussy"),
    ("reverie", "Rêverie", "Debussy"),
    ("flaxen_hair", "The Girl with the Flaxen Hair", "Debussy"),
    ("golliwoggs_cakewalk", "Golliwogg's Cakewalk", "Debussy"),
    ("gymnopedie_1", "Gymnopédie No. 1", "Satie"),
    ("gymnopedie_2", "Gymnopédie No. 2", "Satie"),
    ("gymnopedie_3", "Gymnopédie No. 3", "Satie"),
    ("gnossienne_1", "Gnossienne No. 1", "Satie"),
    ("gnossienne_3", "Gnossienne No. 3", "Satie"),
    ("je_te_veux", "Je te veux", "Satie"),
    ("fur_elise", "Für Elise", "Beethoven"),
    ("moonlight_1", "Moonlight Sonata I", "Beethoven"),
    ("moonlight_3", "Moonlight Sonata III", "Beethoven"),
    ("pathetique_2", "Pathétique Sonata II", "Beethoven"),
    ("ode_to_joy", "Ode to Joy", "Beethoven"),
    ("symphony_5_1", "Symphony No. 5 I", "Beethoven"),
    ("symphony_7_2", "Symphony No. 7 II", "Beethoven"),
    ("eine_kleine_nachtmusik", "Eine kleine Nachtmusik", "Mozart"),
    ("rondo_alla_turca", "Rondo Alla Turca", "Mozart"),
    ("symphony_40_1", "Symphony No. 40 I", "Mozart"),
    ("sonata_k545_1", "Piano Sonata K.545 I", "Mozart"),
    ("lacrimosa", "Lacrimosa", "Mozart"),
    ("dies_irae", "Dies Irae Requiem", "Mozart"),
    ("ave_verum", "Ave Verum Corpus", "Mozart"),
    ("canon_in_d", "Canon in D", "Pachelbel"),
    ("air_g_string", "Air on the G String", "Bach"),
    ("prelude_c_major", "Prelude in C Major BWV 846", "Bach"),
    ("toccata_fugue_d_minor", "Toccata and Fugue in D Minor", "Bach"),
    ("cello_suite_1_prelude", "Cello Suite No. 1 Prelude", "Bach"),
    ("jesu_joy", "Jesu Joy of Man's Desiring", "Bach"),
    ("badinerie", "Badinerie", "Bach"),
    ("minuet_g_major", "Minuet in G Major BWV Anh 114", "Petzold"),
    ("spring", "Spring Four Seasons", "Vivaldi"),
    ("summer_presto", "Summer Presto", "Vivaldi"),
    ("autumn_1", "Autumn I", "Vivaldi"),
    ("winter_1", "Winter I", "Vivaldi"),
    ("winter_2", "Winter II", "Vivaldi"),
    ("sugar_plum", "Dance of the Sugar Plum Fairy", "Tchaikovsky"),
    ("waltz_flowers", "Waltz of the Flowers", "Tchaikovsky"),
    ("trepak", "Trepak", "Tchaikovsky"),
    ("swan_lake_scene", "Swan Lake Scene", "Tchaikovsky"),
    ("sleeping_beauty_waltz", "Sleeping Beauty Waltz", "Tchaikovsky"),
    ("1812_finale", "1812 Overture Finale", "Tchaikovsky"),
    ("mountain_king", "In the Hall of the Mountain King", "Grieg"),
    ("morning_mood", "Morning Mood", "Grieg"),
    ("anitras_dance", "Anitra's Dance", "Grieg"),
    ("solveigs_song", "Solveig's Song", "Grieg"),
    ("nocturne_9_2", "Nocturne Op. 9 No. 2", "Chopin"),
    ("prelude_28_4", "Prelude Op. 28 No. 4", "Chopin"),
    ("raindrop_prelude", "Prelude Op. 28 No. 15 Raindrop", "Chopin"),
    ("minute_waltz", "Waltz Op. 64 No. 1 Minute Waltz", "Chopin"),
    ("funeral_march", "Funeral March", "Chopin"),
    ("fantaisie_impromptu", "Fantaisie-Impromptu", "Chopin"),
    ("hungarian_dance_5", "Hungarian Dance No. 5", "Brahms"),
    ("hungarian_dance_6", "Hungarian Dance No. 6", "Brahms"),
    ("lullaby", "Lullaby Wiegenlied", "Brahms"),
    ("blue_danube", "The Blue Danube", "Johann Strauss II"),
    ("tritsch_tratsch", "Tritsch-Tratsch-Polka", "Johann Strauss II"),
    ("radetzky_march", "Radetzky March", "Johann Strauss I"),
    ("can_can", "Can-Can", "Offenbach"),
    ("barcarolle", "Barcarolle", "Offenbach"),
    ("ride_valkyries", "Ride of the Valkyries", "Wagner"),
    ("bridal_chorus", "Bridal Chorus", "Wagner"),
    ("bumblebee", "Flight of the Bumblebee", "Rimsky-Korsakov"),
    (
        "scheherazade_prince_princess",
        "Scheherazade Young Prince and Princess",
        "Rimsky-Korsakov",
    ),
    ("procession_nobles", "Procession of the Nobles", "Rimsky-Korsakov"),
    ("entertainer", "The Entertainer", "Scott Joplin"),
    ("maple_leaf_rag", "Maple Leaf Rag", "Scott Joplin"),
    ("easy_winners", "The Easy Winners", "Scott Joplin"),
    ("solace", "Solace", "Scott Joplin"),
    ("elite_syncopations", "Elite Syncopations", "Scott Joplin"),
    ("greensleeves", "Greensleeves", "Traditional"),
    ("scarborough_fair", "Scarborough Fair", "Traditional"),
    ("drunken_sailor", "Drunken Sailor", "Traditional"),
    ("irish_washerwoman", "The Irish Washerwoman", "Traditional"),
    ("korobeiniki", "Korobeiniki", "Traditional"),
    ("house_rising_sun", "House of the Rising Sun", "Traditional"),
    ("amazing_grace", "Amazing Grace", "Traditional"),
    ("auld_lang_syne", "Auld Lang Syne", "Traditional"),
]


COMPOSER_ALIASES = {
    "Debussy": ("debussy",),
    "Satie": ("satie",),
    "Beethoven": ("beethoven",),
    "Mozart": ("mozart",),
    "Pachelbel": ("pachelbel",),
    "Bach": ("bach",),
    "Petzold": ("petzold",),
    "Vivaldi": ("vivaldi",),
    "Tchaikovsky": ("tchaikovsky", "chaikovsky"),
    "Grieg": ("grieg",),
    "Chopin": ("chopin",),
    "Brahms": ("brahms",),
    "Johann Strauss II": ("strauss",),
    "Johann Strauss I": ("strauss",),
    "Offenbach": ("offenbach",),
    "Wagner": ("wagner",),
    "Rimsky-Korsakov": ("rimsky", "korsakov"),
    "Scott Joplin": ("joplin",),
    "Traditional": (),
}


TITLE_ALIASES = {
    "arabesque_1": ("Arabesque No. 1", "Arabesque 1", "Première Arabesque"),
    "flaxen_hair": (
        "The Girl with the Flaxen Hair",
        "Girl with the Flaxen Hair",
        "La fille aux cheveux de lin",
    ),
    "golliwoggs_cakewalk": (
        "Golliwogg's Cakewalk",
        "Golliwog's Cakewalk",
        "Golliwogg Cake Walk",
    ),
    "gymnopedie_1": ("Gymnopédie No. 1", "Gymnopédie 1", "1ère Gymnopédie"),
    "gymnopedie_2": ("Gymnopédie No. 2", "Gymnopédie 2", "2ème Gymnopédie"),
    "gymnopedie_3": ("Gymnopédie No. 3", "Gymnopédie 3", "3ème Gymnopédie"),
    "gnossienne_1": ("Gnossienne No. 1", "Gnossienne 1", "1ère Gnossienne"),
    "gnossienne_3": ("Gnossienne No. 3", "Gnossienne 3", "3ème Gnossienne"),
    "moonlight_1": (
        "Moonlight Sonata 1st Movement",
        "Moonlight Sonata I",
        "Piano Sonata No 14 I Adagio sostenuto",
        "Adagio sostenuto Op 27 No 2",
    ),
    "moonlight_3": (
        "Moonlight Sonata 3rd Movement",
        "Moonlight Sonata III",
        "Piano Sonata No 14 III Presto agitato",
        "Presto agitato Op 27 No 2",
    ),
    "pathetique_2": (
        "Pathétique Sonata II",
        "Pathetique Sonata 2nd Movement",
        "Sonata Op 13 mvt 2",
        "Adagio cantabile Op 13",
    ),
    "symphony_5_1": (
        "Symphony No. 5 I Allegro con brio",
        "Symphony No. 5 1st Movement",
        "Symphony 5 Op 67 I",
    ),
    "symphony_7_2": (
        "Symphony No. 7 II Allegretto",
        "Symphony No. 7 2nd Movement",
        "Symphony 7 Op 92 II",
    ),
    "symphony_40_1": (
        "Symphony No. 40 I Molto allegro",
        "Symphony No. 40 1st Movement",
        "Symphony 40 K 550 I",
    ),
    "sonata_k545_1": (
        "Piano Sonata K.545 I Allegro",
        "Sonata K 545 1st Movement",
        "Sonata Facile K 545 Allegro",
    ),
    "dies_irae": ("Dies Irae Requiem", "Dies Irae K 626", "Sequentia Dies Irae"),
    "toccata_fugue_d_minor": (
        "Toccata and Fugue in D Minor",
        "Toccata und Fuge d moll BWV 565",
        "BWV 565",
    ),
    "jesu_joy": (
        "Jesu Joy of Man's Desiring",
        "Jesus bleibet meine Freude",
        "Jesu Joy BWV 147",
    ),
    "spring": ("Spring Four Seasons", "La Primavera", "Spring RV 269 I"),
    "summer_presto": ("Summer Presto", "L'estate Presto", "Summer RV 315 III"),
    "autumn_1": ("Autumn I", "L'autunno I", "Autumn RV 293 Allegro"),
    "winter_1": ("Winter I", "L'inverno I", "Winter RV 297 Allegro"),
    "winter_2": ("Winter II", "L'inverno II", "Winter RV 297 Largo"),
    "swan_lake_scene": ("Swan Lake Scene", "Swan Theme", "Swan Lake Op 20 Scene"),
    "1812_finale": ("1812 Overture Finale", "1812 Overture Op 49"),
    "raindrop_prelude": (
        "Prelude Op. 28 No. 15 Raindrop",
        "Raindrop Prelude",
        "Prelude 15 Op 28",
    ),
    "minute_waltz": ("Minute Waltz", "Waltz Op 64 No 1"),
    "funeral_march": ("Funeral March", "Marche funèbre Op 35"),
    "hungarian_dance_6": ("Hungarian Dance No. 6", "Hungarian Dance 6"),
    "blue_danube": ("The Blue Danube", "An der schönen blauen Donau"),
    "tritsch_tratsch": ("Tritsch-Tratsch-Polka", "Tritsch Tratsch Polka"),
    "can_can": ("Can-Can", "Galop Infernal", "Orpheus in the Underworld Can Can"),
    "ride_valkyries": ("Ride of the Valkyries", "Walkürenritt", "Die Walkure Ride"),
    "scheherazade_prince_princess": (
        "Scheherazade Young Prince and Princess",
        "Young Prince and the Young Princess",
        "Scheherazade III",
    ),
}


def norm(value: str) -> str:
    value = unicodedata.normalize("NFKD", value or "")
    value = "".join(ch for ch in value if not unicodedata.combining(ch))
    return " ".join(re.findall(r"[a-z0-9]+", value.casefold()))


def title_score(wanted: str, candidate: str) -> float:
    wanted_norm = norm(wanted)
    candidate_norm = norm(candidate)
    if not candidate_norm:
        return 0
    ratio = SequenceMatcher(None, wanted_norm, candidate_norm).ratio()
    wanted_tokens = set(wanted_norm.split())
    candidate_tokens = set(candidate_norm.split())
    containment = len(wanted_tokens & candidate_tokens) / max(1, len(wanted_tokens))
    exact_bonus = 0.35 if wanted_norm == candidate_norm else 0
    phrase_bonus = 0.18 if wanted_norm in candidate_norm else 0
    return ratio * 0.52 + containment * 0.48 + exact_bonus + phrase_bonus


def numeric(value: str) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0


COMMON_TITLE_WORDS = {
    "allegro",
    "andante",
    "dance",
    "major",
    "minor",
    "movement",
    "music",
    "piano",
    "prelude",
    "requiem",
    "scene",
    "sonata",
    "song",
    "suite",
    "symphony",
    "waltz",
}


def anchors_for(track_id: str, wanted_title: str) -> set[str]:
    aliases = TITLE_ALIASES.get(track_id, (wanted_title,))
    return {
        token
        for alias in aliases
        for token in norm(alias).split()
        if len(token) >= 5 and token not in COMMON_TITLE_WORDS
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("csv", type=Path)
    parser.add_argument("--top", type=int, default=5)
    parser.add_argument("--output", type=Path)
    parser.add_argument(
        "--allow-conflicts",
        action="store_true",
        help="Also show explicit public-domain rows outside the conflict-free subset.",
    )
    args = parser.parse_args()
    heaps: dict[str, list[tuple[float, int, dict[str, str]]]] = {
        track_id: [] for track_id, _, _ in TRACKS
    }
    anchors = {
        track_id: anchors_for(track_id, wanted_title)
        for track_id, wanted_title, _ in TRACKS
    }

    with args.csv.open(encoding="utf-8", newline="") as source:
        for row_number, row in enumerate(csv.DictReader(source), start=2):
            conflict_free = (
                row["subset:no_license_conflict"] == "True"
                and row["license_conflict"] == "False"
            )
            if (
                row["subset:all_valid"] != "True"
                or row["license"] not in {"publicdomain", "cc-zero"}
                or not row["mid"].endswith(".mid")
                or (not conflict_free and not args.allow_conflicts)
            ):
                continue
            names = " ".join(
                (
                    row["song_name"],
                    row["title"],
                    row["subtitle"],
                    row["composer_name"],
                    row["artist_name"],
                )
            )
            names_norm = norm(names)
            title_candidates = (row["song_name"], row["title"], row["subtitle"])
            for track_id, wanted_title, composer in TRACKS:
                aliases = COMPOSER_ALIASES[composer]
                composer_matches = any(alias in names_norm for alias in aliases)
                if not composer_matches and not any(
                    anchor in names_norm for anchor in anchors[track_id]
                ):
                    continue
                wanted_aliases = TITLE_ALIASES.get(track_id, (wanted_title,))
                score = max(
                    title_score(wanted_alias, title)
                    for wanted_alias in wanted_aliases
                    for title in title_candidates
                )
                if composer == "Traditional":
                    # Traditional rows frequently omit the composer, so require a
                    # very strong title match instead.
                    if score < 0.78:
                        continue
                elif composer_matches:
                    if score < 0.25:
                        continue
                elif score < 0.82:
                    # Composer data is often absent. A strong title match is
                    # still useful, while a weak match without attribution is
                    # too risky to present for review.
                    continue
                score += min(numeric(row["n_views"]), 100_000) / 2_000_000
                score += numeric(row["rating"]) / 250
                if row["is_best_unique_arrangement"] == "True":
                    score += 0.05
                item = (score, row_number, row)
                heap = heaps[track_id]
                if len(heap) < args.top:
                    heapq.heappush(heap, item)
                elif item[:2] > heap[0][:2]:
                    heapq.heapreplace(heap, item)

    output_lines = []
    for track_id, wanted_title, composer in TRACKS:
        output_lines.append(f"\n## {track_id}: {wanted_title} — {composer}")
        for score, row_number, row in sorted(heaps[track_id], reverse=True):
            output_lines.append(
                "\t".join(
                    (
                        f"score={score:.3f}",
                        f"row={row_number}",
                        f"song={row['song_name']!r}",
                        f"title={row['title']!r}",
                        f"composer={row['composer_name']!r}",
                        f"seconds={row['song_length.seconds']}",
                        f"views={row['n_views']}",
                        f"rating={row['rating']}",
                        f"license={row['license']}",
                        f"conflict_free={row['subset:no_license_conflict']}",
                        f"mid={row['mid']}",
                    )
                )
            )
    output = "\n".join(output_lines)
    if args.output:
        args.output.write_text(output, encoding="utf-8")
    else:
        print(output)


if __name__ == "__main__":
    main()
