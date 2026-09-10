# DragonHaven Random Rewards and Odds

Current server verification (10 September): staging schema 70 passed run 34467076186; production remains at schema 65 / v0.05.29. The group lifecycle candidate only seals membership, owned dragon facts and the existing shared chest roll to one receipt. It changes no event content, code catalog, reward pool or probability. Group timing and the 70% Gold / 25% Dragon / 5% Mythical pool are preserved; migration 71 is pending rehearsal.

Last verified: 9 September 2026

Ruleset: v0.05.29 published and verified; staging and production schema 65 verified, economy activation disabled; subsequent calendar hardening below

Source baseline: v0.05.16, with subsequent changes and dormant server rules below

<!-- reference-source-fingerprint: 7eebddf90a3795d2 -->

Calendar hardening after v0.05.29: canonical commands normalize the database
instant to UTC. Legacy offline play retains its local day. Long-adventure
refills and daily return rolls advance only to a later date; a backward clock
cannot reopen a spent daily opportunity. Trial credits use calendar-date
arithmetic across daylight-saving transitions and preserve earned/future date
labels on a backward clock. The 7-day chest pool and 10% return chance are
unchanged. Migration of existing local day labels to a UTC-owned account still
needs an explicit, lossless import bridge before production activation.

The staging house editor now places, moves and removes owned furniture through
revision-fenced server commands. Floor reordering preserves the existing damage
and repair factor, and roaming uses an explicit desired state with the existing
capacity rules. These actions change no event calendar, chest/egg/relic pool,
price, expertise, rank cutoff or random probability. Unknown egg facts remain
hidden. A lost receipt is recovered without repeating an action or rerolling.

The shared command identity schema and durable client intent journal preserve the original request after a timeout. Recovering a completed outcome, including during a mutation pause, creates no new seed or reward roll. The pools, probabilities and pity behavior below are unchanged.

The staging Adventure UI now uses that same command lane for starts, claims and
Wayfinder. A lost claim response cannot grant again; recovering a Wayfinder
keeps its first chosen replacement and consumes one Sigil. The shared duration
helper now also accepts public expertise scores; all duration formulas and
minimums are unchanged, and the extraction consumes no random draws.

Staging house controls now share the existing deterministic floor, repair and
ward price helpers with the evaluator. The saved repair factor remains 25–60%
(40% fallback); this extraction does not draw a new factor or change return,
damage, ward-protection, chest, egg or relic probabilities. Receipt replay
cannot deduct a second floor/repair/ward price.

Staging dragon preferences now use explicit desired-state commands. Highlights
consume no randomness and change no expertise score, rank cutoff or reward.
Selecting the already-favorite dragon does not increment its achievement
counter; no new reward or probability was introduced.

This document describes every player-facing random reward and the other meaningful random gameplay systems currently implemented in DragonHaven. Percentages are exact unless the word “approximately” is used.

The ownership, schedule, lifecycle, and relationship between events, chests,
and eggs are documented separately in
[SPECIAL_EVENTS_CHESTS_AND_EGGS.md](SPECIAL_EVENTS_CHESTS_AND_EGGS.md). The
tables below remain the authoritative reference for their random odds.

## Permanent dragon sex (8 September 2026)

All new starter, ordinary, Sinister and Special eggs have **50% male / 50%
female**, determined with the other fixed egg properties. A full uniform 31-bit
hatch seed supplies the sex bit (`seed XOR (seed >> 16)`, lowest bit). No extra
chest/relic roll is consumed and no reward pool changes. Explicit serialized sex
is preserved; older eggs and dragons deterministically derive the same bit from
their existing seed. Seedless legacy records use a stable identity hash instead
of time or platform hashCode. Hatching/evolution/trade never reroll it. Sex has no
Expertise bonus, reward modifier or effect on rarity/Spectral/Sinister chances.

Training highlights are optional player choices, can be independently toggled
for Might/Arcana/Spirit, and have no effect on scores, caps, odds or rewards.
The subsequent sprite glow and event branding changes consume no random draws.
The annual New Year window now remains recognized through its existing January
end time; this fixes availability evaluation without changing a reward table.

## Reading the tables

The local server-domain candidate reuses the existing Dart reward functions;
the ranges, weighted pools, pity rules and no-duplicate conditions in these
tables have been reviewed and are unchanged. Its `ServerEntropy` uses
HMAC-SHA256 with a private 256-bit seed persisted per intent, separate reward
and identity streams, rejection sampling for uniform integers and 53-bit
fractions. The same private intent can therefore be evaluated again without
changing its rewards. Seeds must be generated by the server and never returned
to players. Production still uses the existing client rules while cutover is
disabled. VM/Deno parity and independent HMAC-vector tests cover the candidate;
they do not replace transaction, rollout or live-server validation.

The dormant migration 52 candidate allocates those seeds with PostgreSQL
`gen_random_bytes(32)` in private intent rows. It only updates detached shadow
copies, has no client-readable seed endpoint, and grants no live rewards.

The canonical loader refuses an implicit inventory normalization that rerolls
missing Chronoshard percentages, changes fixed egg properties, grants starter
collection items or discards unknown owned content. These cases require explicit
reconciliation; the documented live reward probabilities remain unchanged.
Unknown save/entity metadata survives command export by stable identity. Known
counts and inventories are replaced completely, preserving the same consumption
and no-duplicate behavior rather than combining old and new reward inventories.
Altar execution binds to the trusted keeper; unresolved legacy operations must
be reconciled before any new command can draw rewards or consume resources.
The internal import preparer uses the captured Altar wallet and crafted stock;
it does not roll rewards for historical returns. Missing/older ledgers, foreign
owners, ambiguous offline stock and missing fixed Chronoshards require review.
Candidate migration 53 fixes a private preparation seed per immutable source
generation. Its preparation commit forbids wallet grants and makes retries
idempotent. This is a shadow migration boundary, not a new live reward roll.

- “Uniform” means every integer or every eligible item in the stated pool has the same chance.
- Collection rewards never produce duplicates. Their exact per-item odds therefore change as the collection becomes smaller.
- Unless stated otherwise, the coin, gem, egg, relic, and emote rolls made by one chest are independent of each other.
- Opening ten chests performs ten normal openings in sequence. It does not use a special ten-pack odds table.
- A chance is rolled with a cryptographically secure random source for normal game-state rewards. Seeded visual or minigame layouts are identified separately.
- Generated UUIDs, Keeper IDs, cryptographic nonces, and other security identifiers are not gameplay rewards and are outside the scope of this document.

## 1. Chest contents

### 1.1 Complete chest overview

Every integer inside a coin or gem range is equally likely.

| Chest | Coins | Gems | Egg | Relic | Unique chest emote | Other guaranteed reward |
|---|---:|---:|---:|---:|---:|---|
| Wooden | 20–40 | None | 1% base; 3% with egg pity | None | 0.5% | — |
| Silver | 45–80 | 50% none; 25% 1; 25% 2 | 4% base; 12% with egg pity | None | 1% | — |
| Gold | 90–160 | 28% none; 24% each for 2, 3, or 4 | 12% base; 36% with egg pity | 1% | 2% | — |
| Dragon | 180–300 | 10% none; 22.5% each for 4, 5, 6, or 7 | 100% | 2% | 4% | — |
| Mythical | 400–650 | 8–13, uniform | 100% | 4% | 8% | — |
| Sinister | 400–650 | 8–13, uniform | 100%; then 50% Sinister Egg and 50% ordinary Mysterious Egg | 100% | 12% | — |
| Golden Wings Special | Exactly 269 | Exactly 10 | 100% Golden Wings Special Egg | None from the chest itself | 10% | — |
| Witchlight Special | Exactly 313 | Exactly 13 | 100% Witchlight Egg | None from the chest itself | 10% | — |
| Starlight Gift Special | Exactly 250 | Exactly 12 | 100% Starlit Evergreen Egg | None from the chest itself | 10% | — |
| Firstlight Celebration Special | Exactly 365 | Exactly 12 | 100% Turning-Year Egg | None from the chest itself | 10% | — |
| Twinheart Keepsake Special | Exactly 214 | Exactly 14 | 100% Rosebound Egg | None from the chest itself | 10% | — |
| Radiant Festival Special | Exactly 300 | Exactly 15 | 100% Truecolor Egg | None from the chest itself | 10% | — |
| Portrait | None | None | None | None | None | One uniformly selected unowned standard portrait |
| Title | None | None | None | None | None | One uniformly selected unowned standard title |
| Music | None | None | None | None | None | One uniformly selected unowned music track |

Notes:

- A Dragon, Mythical, or Sinister Chest always creates an egg. For a Sinister Chest, the 50/50 egg-type roll happens after that guaranteed egg result.
- An ordinary egg from a Sinister Chest uses the same lineage-rarity curve as an egg from a Mythical Chest.
- Every implemented Special Chest has fixed event-specific currency and egg
  contents. Its 10% no-duplicate chest-emote roll is the only random content.
  One Special Chest definition never inherits or rerolls another event's recipe.
- Portrait, Title, and Music Chests cannot be opened after their relevant collection is complete.
- Their supporter-exclusive counterparts are not in these chest pools.

### 1.2 Egg pity

Egg pity is active only while both of these are true:

1. there is no egg in the egg inventory; and
2. there is no egg in the nest.

While active, the Wooden, Silver, and Gold egg chances are tripled. Dragon, Mythical, and Sinister Chests are already guaranteed and do not change. Once an egg is found during a multi-open, later chests in that same sequence use their normal odds again.

There is no pity system for dragon rarity, relics, emotes, portraits, titles, music, coins, or gems.

### 1.3 Relics from ordinary chests

| Chest | Chance of any relic |
|---|---:|
| Wooden | 0% |
| Silver | 0% |
| Gold | 1% |
| Dragon | 2% |
| Mythical | 4% |
| Sinister | 100% |
| Special, Portrait, Title, Music | 0% |

When a relic drop succeeds, selection uses this weighted pool:

| Relic | Weight | Effect |
| --- | ---: | --- |
| Moral Prism, Order Compass, Soul Mirror, Astral Lens, Chronoshard, Wayfinder Sigil | 10 each | Existing consumable effect |
| Twinstar Brooch | 1 | Double all XP for its wearer |
| Emberheart Brooch | 1 | Double earned Might in Adventures and Trials for its wearer |
| Moonweave Brooch | 1 | Double earned Arcana in Adventures and Trials for its wearer |
| Soulbloom Brooch | 1 | Double earned Spirit in Adventures and Trials for its wearer |

With no brooch acquired, each ordinary relic has `10/64` (15.625%) and each
brooch `1/64` (1.5625%) of a successful relic drop. Each brooch is therefore ten
times rarer than one ordinary relic. A previously acquired brooch is removed
permanently; with `b` still eligible brooches the denominator is `60 + b`.
The overall chest relic-drop chance above remains unchanged. The same weighted
pool applies to the independent 1% S+ Trial relic roll.

All four brooches are unique, permanent, untradeable, and available only from
eligible ordinary chests or S+ Trials. They cannot be bought or crafted. A dragon
can equip only one of the four: replacing it leaves the previous brooch owned
and unequipped. Each brooch can be worn by only one dragon at a time. Expertise
bonuses apply once at claim, within that dragon's Expertise cap, and do not
multiply scores, chest odds, School gains or the other two Expertises. Seasonal
Trials allocate their ordinary balanced reward first, then double only the
matching Expertise actually earned. Twinstar keeps its existing all-XP effect.

Other gameplay-dropped relics remain tradeable. A Chronoshard's permanent
reduction is uniformly selected from whole percentages 10–90: `1/81` each.

### 1.4 Collectible emotes from chests

A successful chest-emote roll selects uniformly from the chest emotes the player does not yet own. Duplicates are impossible. If all 55 are owned, the effective drop chance is 0%.

The initial chance for one specific emote is:

`chest drop chance / 55`

As the collection shrinks, the chance of each remaining emote increases, while the total chest-emote drop chance remains unchanged.

The 55 possible chest emotes are:

Treasure Hello; Coin Eyes; Sleepy Hoard; Egg Surprise; Lucky Gem; Chest Peek; Gem Tears; Golden Laugh; Map Confused; Key Found; Mimic Shock; Coin Rain; Tiny Hoard; Pearl Proud; Treasure Sleep; Locked Out; Crown Try; Dusty Sneeze; Potion Find; Silver Bell; Scroll Wow; Ruby Blush; Sapphire Cool; Jackpot; Dragon Detective; Adored; Treasure Nerves; Tiny Terror; Hoard Fury; Empty-Chest Sulk; Gem Envy; Coin Guilt; Coin Spill Blush; Shy Peek; Doubtful Coin; Tarnished Disgust; Keyhole Curiosity; Relic Awe; Wishing Coin; Lock Relief; Gem Gratitude; Lonely Hoard; Nest Longing; Precious Guard; Gem Gift; Coin Mischief; Lock Impatience; Treasure Overload; Hoard Contentment; Chest Boredom; Misty Eyes; One Little Tear; Treasure Tears of Joy; Empty-Hoard Heartbreak; Treasure Bawl.

### 1.5 Portrait Chest

The standard portrait catalog contains 100 portraits:

| Rarity | Portrait IDs | Catalog count |
|---|---|---:|
| Common | `portrait_001`–`portrait_088` | 88 |
| Rare | `portrait_089`–`portrait_093` | 5 |
| Very Rare | `portrait_094`–`portrait_096` | 3 |
| Legendary | `portrait_097`–`portrait_098` | 2 |
| Infernal | `portrait_099` | 1 |
| Mythical | `portrait_100` | 1 |

The chest does not roll a rarity first. It selects one unowned portrait uniformly from all remaining standard portraits. Therefore:

`current rarity chance = unowned portraits of that rarity / all unowned standard portraits`

A fresh account already owns one randomly selected Common portrait. Before any other standard portrait is collected, the first Portrait Chest therefore has these odds:

| Rarity | Fresh-account first-chest odds |
|---|---:|
| Common | 87/99 = 87.8788% |
| Rare | 5/99 = 5.0505% |
| Very Rare | 3/99 = 3.0303% |
| Legendary | 2/99 = 2.0202% |
| Infernal | 1/99 = 1.0101% |
| Mythical | 1/99 = 1.0101% |

The Founding Supporter portrait is separate and never affects these odds.

### 1.6 Title Chest

The standard title catalog contains 500 titles: every combination of 25 prefixes and 20 roles. One unowned title is selected uniformly at chest opening.

Prefixes: Ancient, Astral, Blazing, Celestial, Crystal, Daring, Dawn, Dreaming, Ember, Enchanted, Eternal, Fabled, Frost, Golden, Hidden, Infernal, Moonlit, Prismatic, Radiant, Royal, Runic, Shadow, Silver, Starborn, Storm.

Roles: Dragon Keeper, Egg Whisperer, Nest Guardian, Scale Scholar, Tower Warden, Flame Friend, Hoard Curator, Wyrm Watcher, Sky Seeker, Rune Reader, Moon Rider, Gem Finder, Chest Charmer, Lore Weaver, Cloud Walker, Spark Tamer, Wing Guide, Haven Herald, Drake Dreamer, Star Sentinel.

A new account starts with one uniformly selected title, so each remaining title initially has a `1/499` chance from the first Title Chest. Later, every unowned standard title has a `1 / remaining title count` chance. The Founding Supporter title is separate and never affects these odds.

### 1.7 Music Chest

The music catalog contains 80 tracks. A Music Chest selects one unowned track uniformly when the chest is opened; the track is not selected when the chest is bought or awarded. Duplicates are impossible.

Every account starts with Rêverie owned and enabled. Consequently, the other 79 tracks each have a `1/79` chance from the first Music Chest on a fresh account. If Rêverie were ever absent from an imported save, it would simply participate like another unowned catalog track.

The complete pool is:

- Debussy: Clair de Lune; Arabesque No. 1; Rêverie; The Girl with the Flaxen Hair; Golliwogg's Cakewalk.
- Satie: Gymnopédie No. 1; Gymnopédie No. 2; Gymnopédie No. 3; Gnossienne No. 1; Gnossienne No. 3; Je te veux.
- Beethoven: Für Elise; Moonlight Sonata – I; Moonlight Sonata – III; Pathétique Sonata – II; Ode to Joy; Symphony No. 5 – I; Symphony No. 7 – II.
- Mozart: Eine kleine Nachtmusik; Rondo Alla Turca; Symphony No. 40 – I; Piano Sonata K.545 – I; Lacrimosa; Dies Irae – Requiem; Ave Verum Corpus.
- Pachelbel: Canon in D.
- Bach: Air on the G String; Prelude in C Major; Toccata and Fugue in D Minor; Cello Suite No. 1 Prelude; Jesu, Joy of Man's Desiring; Badinerie.
- Petzold: Minuet in G Major (BWV Anh.114).
- Vivaldi: Spring – Four Seasons; Summer – Presto; Autumn – I; Winter – I; Winter – II.
- Tchaikovsky: Dance of the Sugar Plum Fairy; Waltz of the Flowers; Trepak; Swan Lake – Scene; Sleeping Beauty Waltz; 1812 Overture – Finale.
- Grieg: In the Hall of the Mountain King; Morning Mood; Anitra's Dance; Solveig's Song.
- Chopin: Nocturne Op. 9 No. 2; Prelude Op. 28 No. 4; Prelude Op. 28 No. 15 “Raindrop”; Waltz Op. 64 No. 1 “Minute Waltz”; Funeral March; Fantaisie-Impromptu.
- Brahms: Hungarian Dance No. 5; Hungarian Dance No. 6; Lullaby (Wiegenlied).
- Johann Strauss II: The Blue Danube; Tritsch-Tratsch-Polka.
- Johann Strauss I: Radetzky March.
- Offenbach: Can-Can; Barcarolle.
- Wagner: Ride of the Valkyries; Bridal Chorus.
- Rimsky-Korsakov: Flight of the Bumblebee; Scheherazade – Young Prince and Princess; Procession of the Nobles.
- Scott Joplin: The Entertainer; Maple Leaf Rag; The Easy Winners; Solace; Elite Syncopations.
- Traditional: Greensleeves; Scarborough Fair; Drunken Sailor; The Irish Washerwoman; Korobeiniki; House of the Rising Sun; Amazing Grace; Auld Lang Syne.

## 2. Eggs and dragon rolls

### 2.1 Egg types

| Egg | Possible family | Incubation | Spectral chance | Other identity rolls |
|---|---|---:|---:|---|
| Starter Egg | One of the 20 Common standard families, uniform | Exactly 1 hour before tap acceleration | 5% base; 10% total if hatched during Golden Hour | Law, moral alignment, size, personality seed |
| Mysterious Egg | One standard non-secret family, using the source-chest rarity curve | Uniformly 4h48m–33h36m in six-minute steps | 5% base; 10% total if hatched during Golden Hour | Law, moral alignment, size, personality seed |
| Sinister Egg | Always Sinisterra | Exactly 6h06m06s | 5% base; 10% total if hatched during Golden Hour | Law and size are random; moral alignment is always Evil and immediately known |
| Golden Wings Special Egg | Always Cluckatrice | Exactly 21 hours | 5% base; 10% total if hatched during Golden Hour | Law, moral alignment, size, personality seed |
| Witchlight Egg | Always Gloamgourd | Exactly 13h13m13s | 5% base; 10% total if hatched during Golden Hour | Law, moral alignment, size, personality seed |
| Starlit Evergreen Egg | Always Hollyfrost | Exactly 25 hours | 5% base; 10% total if hatched during Golden Hour | Law and size; moral is always Good and known at hatch; personality seed |
| Turning-Year Egg | Always Dawnchime | Exactly 24 hours | 5% base; 10% total if hatched during Golden Hour | Law and size; moral is always Neutral and known at hatch; personality seed |
| Rosebound Egg | Always Rosevow | Exactly 14 hours | 5% base; 10% total if hatched during Golden Hour | Law and size; moral is always Good and known at hatch; personality seed |
| Truecolor Egg | Always Spectrumplume | Exactly 18 hours | 5% base; 10% total if hatched during Golden Hour | Law and size; moral is always Good and known at hatch; personality seed |

The family, rarity, alignments, size, initial Spectral roll, hatch duration, and personality seed are fixed when the egg is created. Opening the nest or restarting the app does not reroll them. An Astral Lens reveals the already-fixed rarity; it does not change it.

Starter-Egg tapping changes only the remaining incubation time. It never changes the dragon inside.

### 2.2 Mysterious Egg rarity by source chest

These percentages are conditional on an egg having been created.

| Source chest | Common | Uncommon | Rare | Very Rare | Legendary | Mythical |
|---|---:|---:|---:|---:|---:|---:|
| Wooden | 75% | 20% | 4.5% | 0.45% | 0.049% | 0.001% |
| Silver | 65% | 25% | 8% | 1.7% | 0.28% | 0.02% |
| Gold | 50% | 30% | 14% | 5% | 0.9% | 0.1% |
| Dragon | 25% | 30% | 25% | 15% | 4.5% | 0.5% |
| Mythical | 10% | 20% | 25% | 25% | 17% | 3% |
| Ordinary Mysterious Egg from a Sinister Chest | 10% | 20% | 25% | 25% | 17% | 3% |

After rarity is selected, every standard family of that rarity is equally likely. Secret families are excluded.

The unconditional chance that one chest produces a specific standard family is:

`chest egg chance × rarity chance × (1 / number of standard families in that rarity)`

For a Sinister Chest's ordinary-family route, multiply by the additional 50% ordinary-egg chance.

#### Unconditional egg outcome per opened chest

The next table combines the chest's egg chance with its egg-rarity curve. These are the normal, non-pity odds per chest. “Mythical” means the standard Mythical family Everwyrm; the named secret family is shown separately.

| Opened chest | No egg | Common | Uncommon | Rare | Very Rare | Legendary | Mythical | Secret family |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Wooden | 99% | 0.75% | 0.20% | 0.045% | 0.0045% | 0.00049% | 0.00001% | 0% |
| Silver | 96% | 2.60% | 1% | 0.32% | 0.068% | 0.0112% | 0.0008% | 0% |
| Gold | 88% | 6% | 3.60% | 1.68% | 0.60% | 0.108% | 0.012% | 0% |
| Dragon | 0% | 25% | 30% | 25% | 15% | 4.5% | 0.5% | 0% |
| Mythical | 0% | 10% | 20% | 25% | 25% | 17% | 3% | 0% |
| Sinister | 0% | 5% | 10% | 12.5% | 12.5% | 8.5% | 1.5% | 50% Sinisterra |
| Golden Wings Special | 0% | 0% | 0% | 0% | 0% | 0% | 0% | 100% Cluckatrice |
| Witchlight Special | 0% | 0% | 0% | 0% | 0% | 0% | 0% | 100% Gloamgourd |
| Starlight Gift Special | 0% | 0% | 0% | 0% | 0% | 0% | 0% | 100% Hollyfrost |
| Firstlight Celebration Special | 0% | 0% | 0% | 0% | 0% | 0% | 0% | 100% Dawnchime |
| Twinheart Keepsake Special | 0% | 0% | 0% | 0% | 0% | 0% | 0% | 100% Rosevow |
| Radiant Festival Special | 0% | 0% | 0% | 0% | 0% | 0% | 0% | 100% Spectrumplume |

When egg pity is active, only the first three rows change:

| Opened chest with pity | No egg | Common | Uncommon | Rare | Very Rare | Legendary | Mythical |
|---|---:|---:|---:|---:|---:|---:|---:|
| Wooden | 97% | 2.25% | 0.60% | 0.135% | 0.0135% | 0.00147% | 0.00003% |
| Silver | 88% | 7.80% | 3% | 0.96% | 0.204% | 0.0336% | 0.0024% |
| Gold | 64% | 18% | 10.80% | 5.04% | 1.80% | 0.324% | 0.036% |

### 2.3 Standard family pools

| Rarity | Count | Families |
|---|---:|---|
| Common | 20 | Mossprout, Crystalwhisk, Dustglimmer, Gleamclaw, Emberbun, Copperflame, Spicewing, Bubblefin, Linencloud, Tidescale, Clockskip, Galeear, Thunderpuff, Dreammoth, Dewhorn, Quietstar, Heartwing, Twinflare, Rainbowruff, Harmonytail |
| Uncommon | 10 | Bramblequill, Cinderlynx, Mistmantle, Runehopper, Petaldrift, Ironwhistle, Frostfable, Sunmuzzle, Echofern, Velvetvolt |
| Rare | 6 | Auroracrown, Voidbloom, Coraloracle, Meteorhide, Temporalark, Opalchimera |
| Very Rare | 3 | Eclipseantler, Worldroot, Seraphscale |
| Legendary | 2 | Starforged, Leviathanecho |
| Mythical | 1 | Everwyrm |

Sinisterra is the implemented secret Mythical family. Cluckatrice,
Gloamgourd, Hollyfrost, Dawnchime, Rosevow, and Spectrumplume have the separate
Special type and do not count toward a standard rarity achievement. Every one
is excluded from ordinary Mysterious Egg and Starter Egg pools.

### 2.4 Per-family chance inside one Mysterious Egg

This table is conditional on already having the stated kind of Mysterious Egg. Every family in the same rarity row has the displayed individual chance.

| Family rarity | Wooden source | Silver source | Gold source | Dragon source | Mythical/Sinister ordinary source |
|---|---:|---:|---:|---:|---:|
| Common family | 3.75% each | 3.25% each | 2.5% each | 1.25% each | 0.5% each |
| Uncommon family | 2% each | 2.5% each | 3% each | 3% each | 2% each |
| Rare family | 0.75% each | 1.3333% each | 2.3333% each | 4.1667% each | 4.1667% each |
| Very Rare family | 0.15% each | 0.5667% each | 1.6667% each | 5% each | 8.3333% each |
| Legendary family | 0.0245% each | 0.14% each | 0.45% each | 2.25% each | 8.5% each |
| Everwyrm | 0.001% | 0.02% | 0.1% | 0.5% | 3% |

### 2.5 Sinister Chest family odds

Because every Sinister Chest gives an egg and then performs a 50/50 type roll:

- Sinisterra: exactly 50% per Sinister Chest.
- Any ordinary standard family: 50% multiplied by its value in the final column of the previous table.
- Cluckatrice, Gloamgourd, Hollyfrost, Dawnchime, Rosevow, and Spectrumplume: 0%.

Examples of unconditional Sinister Chest family odds:

- Everwyrm: `50% × 3% = 1.5%`.
- Each Legendary family: `50% × 8.5% = 4.25%`.
- Each Common family: `50% × 0.5% = 0.25%`.

### 2.6 Spectral roll and Golden Hour

Normal, Starter, Sinister, and all six implemented event Special Eggs receive a
`1/20 = 5%` Spectral roll when created. If a non-Spectral egg hatches during
Golden Hour, it receives one extra `1/19` roll. The combined chance is exactly:

`1/20 + (19/20 × 1/19) = 1/10 = 10%`

Golden Hour is 17:00 inclusive through 19:00 exclusive in local device time.
Any future event egg needs its own explicitly configured and documented
Spectral rule.

### 2.7 Alignment, size, and personality

For every non-Sinister egg:

- Lawful, Neutral, and Chaotic each have a `1/3` chance.
- Good, Neutral, and Evil each have a `1/3` chance.
- The two alignment rolls are independent.

Sinisterra is always Evil. Its Lawful/Neutral/Chaotic roll remains uniform.

Dragon size uses one continuous uniform roll transformed into a range from 0.5× through almost 1.5× normal scale. The transformation deliberately makes extreme sizes rarer. The visible size-label odds are approximately:

| Label | Chance |
|---|---:|
| XXS | 5.2786% |
| XS | 5.9915% |
| No special size label | 77.4597% |
| XL | 5.9915% |
| XXL | 5.2786% |

At hatch, personality is generated deterministically from the egg's fixed hatch seed:

- 75% chance of one trait.
- 25% chance of two distinct, compatible traits.
- The first trait is uniform among all 24 traits.
- A second trait is redrawn until it is distinct and not an incompatible opposite.

The 24 traits are: Sleepy, Nosy, Hoarder, Drama Queen, Bookworm, Food Thief, Afraid of Heights, Restless, Shy, Show-Off, Clumsy, Neat Freak, Messy, Curious, Stubborn, Cuddly, Grumpy, Easily Distracted, Night Owl, Early Bird, Splash Lover, Firebug, Attention Seeker, Startles Easily.

Incompatible pairs are Sleepy/Restless, Shy/Show-Off, Neat Freak/Messy, and Night Owl/Early Bird.

## 3. Adventures

### 3.1 Adventure chest reward rolls

| Adventure kind | Chest result |
|---|---|
| Mini | 100% Wooden |
| Short | 20% Wooden; 40% Silver; 35% Gold; 4.5% Dragon; 0.5% Mythical |
| Long | 75% Gold; 23% Dragon; 2% Mythical |
| Group | 70% Gold; 25% Dragon; 5% Mythical |
| Generic Special | A fixed, visible chest defined by that route; no chest-tier roll |
| A Wish on Golden Wings | 100% Golden Wings Special Chest |
| Roots Beneath the Lanterns | 100% Witchlight Chest |
| The Starlight Sleigh | 100% Starlight Gift Chest |
| The Bell Beyond Midnight | 100% Firstlight Celebration Chest |
| The Rosebound Crossing | 100% Twinheart Keepsake Chest for each Keeper |
| The Aurora We Weave | 100% Radiant Festival Chest |

For a normal solo Adventure, the chest tier is rolled once when the Adventure starts, stored in the save, and kept hidden until completion. Reloading cannot reroll it.

The Group Adventure chest is rolled authoritatively by the Supabase server when the lobby starts and is stored on the lobby. Every participant receives the stored result. The server uses the same 70%/25%/5% table shown above.

Opening the awarded chest later performs all of that chest's normal content rolls from section 1. Adventure chest selection and chest opening are therefore two separate random stages.

### 3.2 A Wish on Golden Wings event reward

Completing the birthday Special Adventure guarantees the event-specific reward bundle below. This is not a universal reward table for future Special Events:

- one Special Chest;
- 500 base XP;
- +25 Might, +25 Arcana, and +25 Spirit expertise;
- one Music Chest if the remaining collection capacity allows it; and
- one uniformly random relic from Moral Prism, Order Compass, Soul Mirror, and Astral Lens.

Each event-relic option has exactly a 25% chance. This event pool contains no Chronoshard, Wayfinder Sigil or equipable brooch.

### 3.3 New seasonal Adventure rewards

The five new event bundles contain no random reward selection. Their XP,
balanced Might/Spirit/Arcana grants, event chest, Valentine badge, and Pride
title are guaranteed as specified in `SPECIAL_EVENTS_CHESTS_AND_EGGS.md`.
Opening their awarded Special Chest later has its fixed recipe plus the
separate 10% unique chest-emote roll described in section 1.4.

### 3.4 Wayfinder Sigil

The player chooses Mini, Short, or Long and chooses whether to replace a particular offered Adventure or create another one when a slot is available. The Sigil then selects uniformly from every eligible Adventure definition of that chosen kind that:

- is not already offered;
- is not the route being replaced; and
- is not currently active.

The Adventure kind itself is never random because the player chooses it.

Normal timed Mini, Short, and Long offer rotations are deterministic from the time slot. The global Group Adventure offer is also deterministic. They can look varied, but they are not random rolls.

## 4. Trials

### 4.1 Trial offer type

Outside a seasonal event, every empty Trial slot is selected uniformly from
Cavern Flight, Ruin Breaker, and Runeweaver: `1/3` each. During one active
seasonal event, its event Trial is added as a fourth eligible kind, so Cavern
Flight, Ruin Breaker, Runeweaver, and the active event Trial each have exactly
25% per ordinary refill. On first activation of an event occurrence, all currently
empty slots are instead filled deterministically with that event's Trial (100%).
Existing offers are preserved. A persisted occurrence key prevents repeating
this initial fill. Duplicate kinds may occupy multiple slots. Personal previews
use the same activation/refill rules with a separate occurrence.

### 4.2 Trial reward by grade

Current boundaries published in v0.05.25: Halloween
(Witchlight Ward) uses 500 / 1200 / 1600 / 1800 / 2000 for C/B/A/S/S+.
A and S move below the new 2000 S+ boundary; its C and B remain unchanged.
Valentine uses 650 / 1600 / 2600 / 3900 / 10000; Pride uses
1200 / 2900 / 4800 / 7200 / 12000. New Year uses
500 / 1200 / 2000 / 3000 / 20000. Christmas keeps
500 / 1200 / 2000 / 3000 / 7500. All boundaries are inclusive. Only S+ changes
for New Year, Valentine and Pride. New Year's S+ equals the existing 20000 score
cap. Calibration still records raw scores and never adjusts cutoffs automatically.
Reward pools and the existing server score/action limits remain unchanged.
The birthday addition after v0.05.25 uses 600 / 1500 / 2800 / 4200 / 10000.


XP and expertise are fixed by grade. The chest is the random part shown here.
Since the 8 September 2026 working change, event Trials in a personal test
preview grant this same permanent reward table, including the S+ relic/emote
rolls below and normal constellation credit. Test Special Adventures and their
Special Chests retain their separate production preview exclusions. Preview
event rankings remain separate; Halloween calibration uses accepted attempts
from 8–22 September and does not automatically change any grade cutoff.

| Grade | XP | Standard expertise / seasonal balanced split | Chest result |
|---|---:|---:|---|
| D | 10 | +1 | No chest |
| C | 20 | +2 | 100% Wooden |
| B | 30 | +3 | 85% Wooden; 10% Silver; 5% Gold |
| A | 40 | +4 | 30% Wooden; 50% Silver; 20% Gold |
| S | 50 | +5 | 30% Silver; 69% Gold; 1% Dragon |
| S+ | 69 | +7 | 90% Gold; 9% Dragon; 1% Mythical |

For an event Trial, the expertise total is split as follows: D gives +1 to the
lowest; C gives +1 to both lowest; B gives +1 to all; A gives +2 to the lowest
and +1 to the others; S gives +2 to both lowest and +1 to the highest; S+ gives
+3 to the lowest and +2 to both others. Capped points move to another uncapped
expertise. The achieved score itself is never multiplied by expertise.

Event-ranking position is not random. Best score wins, followed by accuracy,
shortest duration, and earliest submission. Frozen podium rewards are fixed:
place 1 gets a Mythical Chest plus its event gold emote, place 2 a Dragon Chest
plus silver emote, and place 3 a Gold Chest plus bronze emote.

Every S+ completion also independently performs:

- a 1% relic roll; and
- a 10% unique Trial-emote roll.

The relic uses the same weighted ten-relic pool and four lifetime-unique brooch rules described in section 1.3. The emote is selected uniformly from the 55 unowned Trial emotes. If all Trial emotes are owned, the effective emote chance becomes 0%.

The 55 Trial emotes are:

S+ Crown; Perfect Smash; Cavern Soar; Rune Genius; Deep Focus; Victory Roar; Close Call; Speed Blur; Combo Fire; Trial Dizzy; Still Trying; Might Flex; Spirit Wings; Arcana Orbit; New Record; One More Try; Target Lock; Flawless; Training Time; Medal Bite; Power Up; Team Cheer; Trial Zen; Ready!; Champion; Baffled Runes; Trial Tears; Brave Start; Gentle Recovery; Competitive Spark; Missed and Sad; You Can Do It; Pure Euphoria; Fully Spent; Fearless Charge; Finish-Line Relief; Rune Frustration; Humble Victory; Too Confident; Playful Challenge; Proud Tears; Graceful Defeat; Score Shock; Second Wind; Mad at Myself; Inner Calm; Stage Fright; Rune Startle; Not Giving Up; Awkward Stumble; Holding It Together; Frustrated Tears; Spent Tears; Victory Weep; Trial Meltdown.

### 4.3 Seven-day Trial constellation

Claiming a completed seven-day streak gives:

- 95% Dragon Chest; or
- 5% Mythical Chest.

The awarded chest is unopened and later uses its normal content rolls.

Only the first completed Trial on a calendar day (local in legacy play; UTC
in the canonical server lane) can advance the
constellation. Claiming a completed constellation does not make that same day
eligible again. A Trial completed on a later day while the reward is still
waiting can become the first day of the next streak, but at most one day is
carried forward.

## 5. Released-dragon daily return system

If there are no released dragons, no daily roll is made.

If at least one released dragon exists:

1. Once per calendar day (local in legacy play, UTC in the canonical lane) there is a 10% chance that a return event is scheduled.
2. Conditional on a successful day, the arrival second is uniform across all 86,400 seconds of that day.
3. When it resolves, one released dragon is selected uniformly from the released-dragon list.
4. The result is rolled from the table for that dragon's current stage, moral alignment, and law alignment.

Outcome abbreviations used below:

- W/S/G/D/M = Wooden/Silver/Gold/Dragon/Mythical Chest.
- Visit = the dragon temporarily visits for 24 hours as a Hatchling, 48 hours as a Wyrmling, or 72 hours as an Ascended dragon.
- Special = a non-Sinister Special Adventure becomes available for 48 hours.
- Sinister = a Sinister Adventure becomes available for 48 hours.
- Minor damage, damage, and major damage cost 25%, 40%, and 60% of the affected room's price to repair.
- Mischief, major mischief, spotted, and nothing do not remove possessions.

### 5.1 Hatchling return outcomes

| Moral / Law | Exact outcome weights |
|---|---|
| Good / Lawful | 80% W; 15% S; 5% Visit |
| Good / Neutral | 65% W; 20% S; 10% Visit; 5% Special |
| Good / Chaotic | 50% W; 20% S; 5% G; 15% Visit; 10% Special |
| Neutral / Lawful | 70% Visit; 20% Special; 10% Nothing |
| Neutral / Neutral | 50% Visit; 25% Special; 25% Nothing |
| Neutral / Chaotic | 30% Visit; 30% Special; 40% Nothing |
| Evil / Lawful | 45% Mischief; 25% Minor damage; 20% Sinister; 10% Spotted |
| Evil / Neutral | 40% Mischief; 30% Minor damage; 20% Sinister; 10% Spotted |
| Evil / Chaotic | 50% Mischief; 20% Minor damage; 15% Sinister; 15% Spotted |

### 5.2 Wyrmling return outcomes

| Moral / Law | Exact outcome weights |
|---|---|
| Good / Lawful | 70% S; 24% G; 1% D; 5% Visit |
| Good / Neutral | 55% S; 25% G; 2% D; 8% Visit; 10% Special |
| Good / Chaotic | 40% S; 25% G; 5% D; 1% M; 14% Visit; 15% Special |
| Neutral / Lawful | 60% Visit; 30% Special; 10% Nothing |
| Neutral / Neutral | 40% Visit; 35% Special; 25% Nothing |
| Neutral / Chaotic | 25% Visit; 40% Special; 35% Nothing |
| Evil / Lawful | 50% Damage; 20% Mischief; 25% Sinister; 5% Spotted |
| Evil / Neutral | 45% Damage; 25% Mischief; 25% Sinister; 5% Spotted |
| Evil / Chaotic | 35% Damage; 35% Mischief; 20% Sinister; 10% Spotted |

### 5.3 Ascended return outcomes

| Moral / Law | Exact outcome weights |
|---|---|
| Good / Lawful | 55% G; 35% D; 5% M; 5% Visit |
| Good / Neutral | 45% G; 30% D; 3% M; 10% Visit; 12% Special |
| Good / Chaotic | 30% S; 30% G; 20% D; 4% M; 6% Visit; 10% Special |
| Neutral / Lawful | 50% Visit; 40% Special; 10% Nothing |
| Neutral / Neutral | 30% Visit; 45% Special; 25% Nothing |
| Neutral / Chaotic | 20% Visit; 50% Special; 30% Nothing |
| Evil / Lawful | 60% Major damage; 10% Mischief; 25% Sinister; 5% Spotted |
| Evil / Neutral | 50% Major damage; 15% Mischief; 30% Sinister; 5% Spotted |
| Evil / Chaotic | 40% Major damage; 30% Major mischief; 25% Sinister; 5% Spotted |

If another returning Special Adventure is already active, a new Special result becomes a Visit instead, and a new Sinister result becomes Mischief instead.

### 5.4 Dragon Ward and damaged-floor roll

When a damage result occurs, the Dragon Ward receives a separate prevention roll:

| Dragon Ward level | Prevention chance |
|---:|---:|
| 0 | 0% |
| 1 | 50% |
| 2 | 75% |
| 3 | 90% |

If damage is not prevented:

- a Lawful released dragon targets the most expensive undamaged room;
- a Neutral or Chaotic released dragon selects uniformly from all undamaged floors.

## 6. New-account and recovery-only rolls

### 6.1 New account

A new account rolls:

- one Starter Egg family uniformly from the 20 Common families: 5% per family;
- the Starter Egg's Spectral state, alignments, size, and personality seed as described in section 2;
- one Common portrait uniformly from portraits 001–088: `1/88` each; and
- one standard title uniformly from all 500 titles: `1/500` each.

Rêverie is granted deterministically and is not rolled.

### 6.2 Legacy-save repair

These rolls are used only to repair old or incomplete saves, not during ordinary play:

- If a save owns more Chronoshards than it has stored percentage values, every missing value is filled uniformly from 10% through 90%.
- If a legacy save has no valid portrait, it receives one random Common portrait.
- If a legacy save has no valid title, it receives one random standard title.

## 7. Random gameplay patterns without random loot

These systems use randomness but do not directly choose a reward item. Rewards remain score- or action-based.

### 7.1 Trial layouts

- Cavern Flight is seeded by the Trial-offer ID. Each obstacle has a gap center uniformly from 30% to 70% of the playfield, a 50% crystal state, a uniform movement phase, and—after four obstacles have been passed—a 25% chance to move. Replaying the same persisted offer recreates its seeded sequence.
- Runeweaver is seeded by the Trial-offer ID combined with the selected dragon's hatch seed. Every added rune is uniform among the available rune keys. From round six onward, rune positions are shuffled.
- Ruin Breaker uses timing and player input; it does not roll a reward-affecting target sequence.
- Every online seasonal Trial uses the server-provided seed; local preview/test
  seeds remain injectable. These random layouts never roll a reward item.
  Witchlight retains its seeded draws (target, unused lane, palette color and
  answer position) and six pumpkin faces. It now alternates memory and tracing,
  with no third timing game.
- Witchlight uses the target choice for six similar pumpkin faces, now rendered
  as six individual painted sprites. The artwork itself adds no random draw or forgiveness. Its Spirit
  corridor gets a fresh 32-bit seeded shape on every challenge and has no random
  forgiveness roll. Six original points are jittered (x up to 9% of width, y up
  to 6% of height), normalized to the original arc length and recentered. Bounds
  rejection allows 256 attempts before the original shape fallback; a random
  horizontal reflection also varies direction.
  Spirit visibly widens that corridor from 24 to 32 logical pixels at 400
  expertise; leaving it always fails. The seeded lane draw is unused there.
- The four rebuilt games derive a separate 31-bit board seed from the run's
  seeded stream. Christmas draws a uniform parcel symbol from three choices on each scheduled
  arrival, independently of deliveries; missed parcels still consume their draw.
  New Year draws one of four starting phrases uniformly, then follows an
  original 32-note melody (C5, D5, E5, G5). Later chords, spacing and acceleration
  are deterministic functions of active play time; no random lane/spacing draw
  occurs per note. Christmas arrival intervals and each parcel's fixed travel time shorten
  deterministically; the queue does not add another random draw. See the Special
  Events reference for exact pacing, assistance and three-strike rules.
- Valentine independently shuffles eligible cells on each 3×5 board and selects
  four thorn cells per side, protecting starts and goals. Breadth-first search
  accepts only paired layouts solvable in 7–16 moves, for up to 160 attempts,
  then uses a fixed reachable fallback. It never awards the same paired state
  twice in one board. Directional movement and hints are deterministic.
- Pride uses a shuffled depth-first search for a self-avoiding route of 6–11
  cells on a 4×4 grid, with a uniform left-edge source row and a right-edge sink.
  It tries up to 100 starts, then a fixed route. Decoys use equal elbow/straight
  choices; every cell receives 0–3 uniformly selected initial quarter turns.
  An already solved initial board is rotated out of solution. Each connected
  cell scores at most once per board. No old random Spirit forgiveness remains
  in these four games. Assistance, scoring and caps are documented in section 3
  of `SPECIAL_EVENTS_CHESTS_AND_EGGS.md`; reward tables stay unchanged.

The v0.05.23 event stop is deterministic and changes no reward roll. The new
Jingle Bells performance is original synthesis with no random sample source;
it replaces a temporary alias only, outside the Music Chest collection.

### 7.2 Dragon Academy lesson patterns

Dragon Academy rewards and graduation outcomes are determined by scores and previously earned stars, not random reward rolls. The lesson challenges do use random layouts:

- Rune Rush moves the rune uniformly among nine positions.
- Crystal Chase selects one of nine targets.
- Ember Reflex waits uniformly from 600 through 1,499 milliseconds before its cue.
- Sigil Memory selects one of six sigils.
- Scale Order shuffles the numbers 1–6 after every completed sequence.
- Shadow Match selects one of six targets, selects one of four visual-difference types, and then changes to a different target.
- Breath Balance uses a moving phase and has no additional target roll.
- Cloud Weave changes to a different lane target.
- Safe Hoard selects one of six unsafe choices and then changes to a different one.
- Star Compass/Constellation Trace shuffles all six constellation nodes after every completed path.

A mentor's one-error protection is deterministic and does not have a success roll.

### 7.3 Tower roaming and room interactions

- During game-state roaming updates, a correctly placed idle roaming dragon has a 20% chance to consider moving. A dragon that needs a valid room always moves when space permits.
- If preferred and non-preferred rooms both exist, the dragon uses its lineage's preferred room pool 65% of the time. Primary rooms appear twice in that preferred pool and secondary rooms once, so primary rooms receive double weight inside the preferred selection.
- An eligible rare room interaction has a 5% trigger chance, subject to its 12-hour per-dragon cooldown. The eligible dragon is uniform; if furniture-tag interactions match, the interaction is uniform among those matches. The room/floor must exist, match the dragon's location and be undamaged. In canonical play the private server roll is recorded in the original command receipt, so retrying a lost response cannot roll again. This is cosmetic and grants no coins, XP or items.
- While a tower room is visibly open, the controllable dragon's purely visual wander check occurs every five seconds. Its move chance is 12% in Deep Night, 20% at Night, 45% at Dusk, 60% at Dawn, 82% in Morning, and 95% during Day or Golden Hour. The visual destination is random within the room's safe movement area.

None of these ambient rolls grant or remove inventory, XP, currency, or expertise.

### 7.4 Jukebox shuffle

When Shuffle is enabled, the selected music tracks are randomly shuffled into a playback queue. With Repeat disabled, playback stops after that queue is exhausted. With Repeat enabled, a new shuffled queue is created for the next cycle. This changes playback order only and has no reward effect.

## 8. Important systems that are not random

- Shop-bought relics are selected directly by the player; they are not mystery purchases.
- Dragon emote packs always contain their ten specified exclusive emotes.
- The Founding Supporter Pack has fixed contents.
- Standard Adventure offer rotations are deterministic by time slot.
- A Long Adventure loses exactly 15 minutes per point of its matching
  Expertise, while retaining its one-day minimum duration.
- Group Adventure selection is deterministic from the shared server slot.
- Dragon Academy star rewards, graduation, valedictorian, and dropout outcomes are score-based.
- Moral Prism, Order Compass, Soul Mirror, and Astral Lens reveal fixed properties and never reroll them.
- A Chronoshard's percentage is random only when that specific Chronoshard is created; using or trading it preserves the stored value.
- Evolution path and Mastery are determined by expertise and player progression, not by chance.

## 9. Source-of-truth files

The active implementation was cross-checked against:

- `lib/providers/household_provider.dart` — chest opening, collection chests, egg creation, relics, Spectral bonus, starter state.
- `lib/providers/dragonhaven_systems.dart` — Trials, Adventures, Wayfinder Sigil, released-dragon returns, Dragon Ward, roaming.
- `lib/models/chest.dart` — chest types and reward models.
- `lib/models/dragon_egg.dart` and `lib/models/dragon_lineage.dart` — egg persistence and dragon family catalog.
- `lib/models/pet.dart` — alignments, personality, size labels, progression.
- `lib/models/day_phase.dart` — base and Golden Hour Spectral odds.
- `lib/models/trial.dart` — grade thresholds and Trial reward tables.
- `lib/models/adventure.dart` — Adventure chest curves and Special Adventure reward definitions.
- `SPECIAL_EVENTS_CHESTS_AND_EGGS.md` — event/chest/egg ownership and lifecycle catalog; exact random odds remain authoritative in this document.
- `lib/models/profile_portrait.dart`, `lib/models/account_title.dart`, and `lib/models/music_track.dart` — collection pools.
- `lib/models/dragon_emote.dart` — collectible emote pools.
- `lib/screens/trial_game_screen.dart` and `lib/screens/dragon_school_screen.dart` — random challenge layouts.
- `lib/screens/seasonal_trial_game.dart` — seeded seasonal Trial layouts and
  the three expertise-assist rules.
- `android/app/src/main/kotlin/nl/dragonhaven/app/MainActivity.kt` — native jukebox shuffle.
- `supabase/migrations/202608240007_group_adventure_duration_rules.sql` — authoritative Group Adventure chest roll.

When any of these source tables change, this document must be reviewed and updated in the same change. Run `dart run tool/reference_documentation_guard.dart --update` only after that review; the corresponding test rejects stale source fingerprints.

## Egg Altar: Return to the Weave

| Return | Guaranteed Shell Fragments | Essence result | Independent Weaveheart bonus |
|---|---:|---|---|
| Ordinary inventory egg | 5 | 25% for 1 | 2% for 1 |
| Sinister Egg (extra confirmation) | 25 | Always 3, 4 or 5, each with 1/3 probability | 10% for 1 |

The Essence and Weaveheart rolls are independent. Sinister eggs always grant
Essence and have five times the ordinary Weaveheart chance (10% instead of 2%),
awarding exactly one heart when successful. After 39 returns without a
Weaveheart, the next return guarantees exactly one heart for either egg type.
Any successful heart bonus resets the counter. One actual egg advances the
counter once, including Sinister eggs. The counter persists per account, with no daily cap.
All eligible ordinary eggs use the same table, independent of hidden rarity,
Spectral status, hatch seed or source. Special-family, tagged, nested and
trade-reserved eggs cannot be returned. Retrying a committed action never rolls
again, consumes another egg or grants another reward. Existing receipts and
wallet balances are preserved when the reward table is updated; new returns
use the current table.

| Crafted consumable | Fragments | Essence | Weaveheart | Fixed information/action |
|---|---:|---:|---:|---|
| Moral Echo | 20 | 1 | 0 | Egg moral alignment |
| Order Sigil | 30 | 2 | 0 | Egg law alignment |
| Astral Lens | 50 | 5 | 1 | Egg rarity |
| Weave Oracle | 125 | 12 | 2 | Egg family and rarity |
| Nameweaver's Quill | 10 | 1 | 0 | Rename one already-named hatched dragon |

Scans never reroll the egg and do not consume another relic for known information.
Tagged eggs may be scanned. Oracle and Quill are Altar-exclusive; existing Astral
Lens drops and shop remain unchanged, as do the seven-member MysticRelic pools.
Materials and crafted stock are not tradeable. Beacon donations buy only shared
cosmetic progress; there are no additional rolls or improved loot odds.

Sources: lib/models/egg_altar.dart, lib/providers/egg_altar_systems.dart and
supabase/migrations/202609070042_egg_altar.sql, with the forward reward update in
supabase/migrations/202609070044_sinister_altar_rewards.sql. Witchlight challenge generation is
in lib/screens/seasonal_trial_game.dart and lib/widgets/witchlight_trial_widgets.dart.

## Dormant server chest opening (audit phase 4B)

Migration 45 adds server-side opening for ordinary, Sinister, Special, portrait,
title and music chest instances. All existing probabilities, inclusive currency
ranges and eligible pools above are preserved. The client catalog snapshot is
checked by `tool/economy_chest_catalog.dart --verify`; future catalog changes
require a forward migration. Oracle and Nameweaver's Quill remain Altar-only;
Astral Lens remains in the normal relic pool.

Each owner-locked transaction handles at most ten distinct owned chest IDs.
The stored receipt and ledger prevent both request retries and a new request ID
from rerolling an already opened chest. A full vanity collection leaves its
chest unopened. Pity is recomputed after each granted egg and is inactive while
an egg remains in inventory or in the nest. Independent server draws preserve
Sinister's 50% Sinisterra chance, guaranteed relic, and ordinary fallback pool.
Chronoshard's 10-90% value is stored once per relic instance; all four brooches' lifetime
acquisition marker excludes it from subsequent drops, including after consumption.

Special chest identity must be supplied by the trusted import/grant procedure;
unknown or missing event IDs fail without consuming the chest. Special eggs use
the event's exact incubation seconds and fixed moral/hatch-disclosure rule.
Opening receipts omit hidden lineage, hatch seed and personality. The future
hatch flow still needs to implement the Golden Hour spectral bonus.

This path is not activated for players. The existing app opening flow and
production economy authority flags remain unchanged. Migration 46 blocks legacy
inventory synchronization/import for a future server-owned account, while legacy
accounts keep their existing behavior. End-to-end cutover, instance conversion,
server egg lifecycle and client reconciliation remain separate audit work.

### Jukebox cycle correction (0.05.25)

Shuffle still randomizes each full selected playlist with Kotlin Random.Default,
without duplication within a cycle. Removing temporary event music rebuilds the
remaining queue from the current saved selections, including newly acquired
tracks. A removed song does not consume the new cycle when repeat is off.
Preference reevaluation and lifecycle callbacks do not draw gameplay entropy.
MIDI performance-level normalization changes audio only, with no reward changes.

## Birthday Trial and Christmas pacing (9 September 2026)

Wishcake Tower uses C/B/A/S/S+ thresholds 600/1500/2800/4200/10000, inclusive.
It shares the existing grade chest, XP, balanced expertise, relic and emote rolls;
no new reward pool or podium prize is introduced. Its seeded initial movement
direction is 50/50, followed by deterministic alternating sides. Overlap,
perfect placement, width restoration and acceleration are deterministic.
The separate 31-bit game seed comes from the existing seasonal run stream.
Birthday music and animated decoration make no reward-affecting random draws.
The 80-song Music Chest collection is unchanged.

Christmas starts with a 35-second lead in both existing pacing curves (the
former 40-seconds-remaining mark of its base 75-second timer): first arrival
interval 1.315 seconds, first travel 2.65 seconds plus existing Might help.
Acceleration continues to the same .36s arrival and .95s base travel floors.
Parcel symbols remain uniformly distributed over the same three choices.


## Sunwake and Harvestmoon / revised grade boundaries (v0.05.27 candidate)

The approved event Adventures each grant fixed 650 XP, +10 per expertise and
one distinct Special Chest. Each chest grants exactly 300 coins, 12 gems and
its own guaranteed Special Egg: Solmanta (20 hours) or Ciderhorn (18 hours).
Good is fixed and revealed on hatch. Spectral chances are 5% / 10% Golden Hour;
shared 50/50 gender, law, personality and size draws happen once at egg creation.
No ordinary egg pool includes either Special family. The existing Special-tier
10% unique chest-emote roll is retained. Podium prizes use the established
mythical/dragon/gold rewards with event-specific medal emotes; test results
never produce podium awards or permanent Conclave decorations.

Sunwake uses a seeded uniform choice among three safe lanes per gate. The
fixed-step movement, hitboxes, currents and score depend on play, not frame
rate. The first gate is at .20s, speed min(1.6,.55+t*.004+t*t*.00011) arena
heights/s and gate interval max(.56,.98-t*.0055)s. Reef collision width is
.25-.025*normalized Might, plus .026 dragon radius. A grabbed dragon follows a dragged target
at at most 1.65 arena widths/s; releasing stops pursuit. Passive current
applies only while not held. Safe-lane odds and points are unchanged; reef
hitboxes remain as approved and speed increases smoothly during the endless run.
Only the third collision ends Sunwake; no timer, 20,000-point or 200-action limit
is used by the next app build. Reward grade odds and per-gate points are unchanged.
Harvestmoon independently chooses fruit among three types and an initial
rotation among four turns. A single-fruit shape has chance .10 plus .035 times
each expertise normalized/capped at 400, maximum .205. Otherwise each of seven
multi-fruit shapes is equally likely. Refill creates three shapes; invalid
placement does not redraw. No-fitting-tray resets the basket, loses one of
three lives and deducts 30. Full-shape previews and row-fall animation do not
roll additional shapes or grant additional score. The full footprint is centered
on the thumb, snapped to the grid, and is the only moving preview. Clipped edge
placements are invalid; releasing uses the same anchor as the preview.
Placement is blocked during
the .62s harvest animation; reduced motion uses the final board immediately.
These seeds never reroll egg/reward provenance.

Both new Trials use inclusive C/B/A/S/S+ 500/1500/3000/5000/8000. Christmas S+
is 7500 and birthday S+ is 10000; their other cutoffs are unchanged. Birthday
now ends at its first miss; the server accepts legacy three-miss submissions
for rollout compatibility. All Trial chest/relic/XP/expertise odds remain the
shared grade tables. Conclave milestones 1/5/15/30/60 give decoration only.

Seasonal hatch achievements accept normal and Spectral hatchlings alike. Migration 65
allows the exact shipped seasonal podium emotes in friend and Conclave chats, retaining
friendship, membership, recipient preferences, payload bounds and rate limits.


The subsequent house import/care candidate adds loss-detection for furniture,
room and resident/care facts before canonical rules run. Starlight Treat controls
reuse the existing active-dragon command: 3 gems, 25 XP (Twinstar doubles it),
+12 Joy/Energy/Comfort capped at 100. No Special schedule, chest/egg pool,
probability, relic distribution or reward price changes. Invalid imported facts
require reconciliation rather than a random replacement or silent repair.


Runeweaver now closes a completed input sequence before the 150 ms tap glow
awaits. Earlier tap callbacks cannot complete the same round again or clear a
newer glow. A second event after the final rune is ignored. Sequence generation,
shuffle/Arcana help, display durations, grade cutoffs and reward pools remain
unchanged. This fixes repeated completion/out-of-range access during fast taps;
it does not introduce client scores into canonical server commands.


### Academy input authority (10 September 2026, next release)

The ten Academy lessons share one seeded input model between app and server.
Rune/grid targets, shadow variants and shuffled orders retain their uniform
choices. Cloud Weave now selects its first target from its actual three lanes
(the old screen could initially pick an invisible fourth, fifth or sixth lane).
Reflex cues still wait 600–1499 ms; memory previews last 820 ms. The breath phase
uses elapsed time rather than render-frame count. A mentor protects one mistake.
At most one tap per 25 ms is recorded, bounding a 20-second transcript to 800
inputs and 3,200 encoded bytes. Inputs identify buttons and times, never score.
New stars still grant 5 XP and +1 expertise per pupil; all three official attempts
and existing graduation outcomes remain. Abandoning an authoritative attempt
uses a zero-score attempt; expired attempts cannot award XP. Starting, finishing,
recovery and one atomic reward are implemented in the isolated canonical lane;
production ownership has not changed.


## Shared trial input models (next release, in progress)

The public Sunwake lane generator now uses checkpointable xorshift32 with
rejection sampling for `nextInt`; reward rolls still use private server entropy.
The seed determines layout only. Simulation runs on integer 120 Hz steps, with
the existing three uniform lane choices and all existing expertise assistance.
Checkpoint/restore retains the generator state, active gates, position, current,
steering target and timing without rerolling any gate.

Cavern Flight, Ruin Breaker and Runeweaver now expose pure gameplay models.
Cavern uses fixed 10 ms steps and the same 43-by-31 hitbox in a 360-by-600
reference arena, adjusted by Spirit, rather than changing collision difficulty
with device pixels. Ruin retains its 330 ms impact pause, all point values,
Might zones, thirty turns and three misses. Runeweaver retains its seeded
sequence, five symbols, later position shuffling, one Arcana echo, existing
show durations and no idle timeout. Rapid final-rune taps still count once.

Christmas and New Year arrivals use fixed 10 ms scheduling; their progression,
melody/chords, assistance and three-error limit are unchanged. Valentine and
Pride keep their generated solvable puzzles, hints, cooldowns, once-only cell
credit and existing points. Witchlight route generation and whole-segment edge
checks are now shared with the verifier; shape count, randomness and odds stay
the same. Input chunks contain control identities and elapsed deltas only,
never a client reward or score. This foundation has native/JavaScript parity;
server trial settlement and live cutover remain separate open work.

### Verified Trial inputs and constellation command (10 September 2026)

The canonical command candidate derives all eleven Trial scores from replayed
controls, then uses the existing grade reward function and private server reward
entropy once. Public layout seeds and checkpoints never select reward drops.
The seven-day constellation UI now uses the existing authoritative claim command;
its 95% Dragon / 5% Mythical chest pool and once-only ready flag are unchanged.
Abandoning a reserved Trial grants nothing. Existing event-preview Trials retain
normal permanent Trial rewards. The full command results and private checkpoints
agree in VM/Deno tests; live social settlement and account cutover are pending.


### Atomic social claim candidate (10 September 2026)

Group rewards consume the lobby's stored chest tier; claiming does not reroll
its 70% Gold / 25% Dragon / 5% Mythical result. The shared command applies the
stored XP/focus/stat reward and existing equipped-brooch multipliers/caps once.
Valentine partner claims retain 650 XP, +8 Might/Arcana/Spirit, the Twinheart
Keepsake chest and the existing preview-reward policy. Podium claims retain
first/second/third Mythical/Dragon/Gold chests and the corresponding event emote.
No drop odds, no-duplicate rule, chest contents or redemption reward changes.
The candidate seals owner/source facts at reservation and atomically commits
inventory plus the normalized source acknowledgment. A changed source is refused
without paying. Shadow social claims are disabled except explicit staging tests;
full social lifecycle, migration and live authority activation remain pending.


### Explicit legacy clock bridge (10 September 2026)

Cloud uploads now convert known local timer instants to UTC on the device before
canonical import. Event-preview expiry, dismissal, adventure deadlines, hatch
clocks and cooldowns keep the same epoch; schedules, durations, saved day credits,
reward pools and counts are unchanged. A server import refuses unresolved local
times rather than guessing the device timezone. Unknown metadata is preserved.
The Trial startup reservation is deferred until its route has finished building;
this fixes account-consumer notifications during build without altering gameplay.

### Social reservation authority candidate (10 September 2026)

The same verified database reservation view now supplies dragon availability
in command evaluation and display. Waiting/current group lobbies, unfinished
group rewards and pending/active partner adventures retain their dragon until
the owner leaves, the source closes or the reward is acknowledged. Obsolete
social bindings clear without altering solo journeys. Conflicting social,
Trial, Academy pupil or mentor reservations are refused, and a changed source
invalidates an in-flight command atomically. The feature is dormant outside
explicit staging rehearsal until full migration/cutover. Existing event
schedules, expertise bonuses, reward tables, drop weights and preview rules
are unchanged. Old authenticated lifecycle/ack RPCs remain available only for
legacy accounts; promoted accounts must use canonical commands.
