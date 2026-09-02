# DragonHaven Random Rewards and Odds

Last verified: 2 September 2026

Ruleset: app version `v0.05.04`

Source baseline: commit `6d28e76`

This document describes every player-facing random reward and the other meaningful random gameplay systems currently implemented in DragonHaven. Percentages are exact unless the word “approximately” is used.

## Reading the tables

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
| Special | Exactly 269 | Exactly 10 | 100% Special Egg | None from the chest itself | 10% | — |
| Portrait | None | None | None | None | None | One uniformly selected unowned standard portrait |
| Title | None | None | None | None | None | One uniformly selected unowned standard title |
| Music | None | None | None | None | None | One uniformly selected unowned music track |

Notes:

- A Dragon, Mythical, or Sinister Chest always creates an egg. For a Sinister Chest, the 50/50 egg-type roll happens after that guaranteed egg result.
- An ordinary egg from a Sinister Chest uses the same lineage-rarity curve as an egg from a Mythical Chest.
- A Special Chest always contains its Special Egg, 269 coins, and 10 gems. The chest-emote roll is the only random content inside that chest.
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

When a relic drop succeeds, one eligible relic is selected uniformly:

- Moral Prism
- Order Compass
- Soul Mirror
- Astral Lens
- Chronoshard
- Wayfinder Sigil
- Twinstar Brooch, but only if it has never been obtained before

Before the Twinstar Brooch has ever been obtained, each of the seven relics has a `1/7` share of a successful relic drop. Afterwards, the Brooch is permanently removed from the pool and each of the remaining six has a `1/6` share. The overall relic-drop chance does not decrease.

The Twinstar Brooch is unique and always untradeable. Other gameplay-dropped relics are tradeable. A randomly granted Chronoshard receives a permanent reduction value selected uniformly from every whole percentage from 10% through 90%, so each value has a `1/81` chance conditional on obtaining a Chronoshard.

### 1.4 Collectible emotes from chests

A successful chest-emote roll selects uniformly from the chest emotes the player does not yet own. Duplicates are impossible. If all 25 are owned, the effective drop chance is 0%.

The initial chance for one specific emote is:

`chest drop chance / 25`

As the collection shrinks, the chance of each remaining emote increases, while the total chest-emote drop chance remains unchanged.

The 25 possible chest emotes are:

Treasure Hello; Coin Eyes; Sleepy Hoard; Egg Surprise; Lucky Gem; Chest Peek; Gem Tears; Golden Laugh; Map Confused; Key Found; Mimic Shock; Coin Rain; Tiny Hoard; Pearl Proud; Treasure Sleep; Locked Out; Crown Try; Dusty Sneeze; Potion Find; Silver Bell; Scroll Wow; Ruby Blush; Sapphire Cool; Jackpot; Dragon Detective.

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
| Special Egg | Always Cluckatrice | Exactly 21 hours | Always 0% | Law, moral alignment, size, personality seed |

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
| Special | 0% | 0% | 0% | 0% | 0% | 0% | 0% | 100% Cluckatrice |

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

Sinisterra and Cluckatrice are secret Mythical families and are not part of any ordinary Mysterious Egg or Starter Egg pool.

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
- Cluckatrice: 0%.

Examples of unconditional Sinister Chest family odds:

- Everwyrm: `50% × 3% = 1.5%`.
- Each Legendary family: `50% × 8.5% = 4.25%`.
- Each Common family: `50% × 0.5% = 0.25%`.

### 2.6 Spectral roll and Golden Hour

Normal, Starter, and Sinister Eggs receive a `1/20 = 5%` Spectral roll when created. If a non-Spectral egg hatches during Golden Hour, it receives one extra `1/19` roll. The combined chance is exactly:

`1/20 + (19/20 × 1/19) = 1/10 = 10%`

Golden Hour is 17:00 inclusive through 19:00 exclusive in local device time. Special Eggs are explicitly excluded and can never become Spectral through this system.

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
| A Wish on Golden Wings | 100% Special Chest |

For a normal solo Adventure, the chest tier is rolled once when the Adventure starts, stored in the save, and kept hidden until completion. Reloading cannot reroll it.

The Group Adventure chest is rolled authoritatively by the Supabase server when the lobby starts and is stored on the lobby. Every participant receives the stored result. The server uses the same 70%/25%/5% table shown above.

Opening the awarded chest later performs all of that chest's normal content rolls from section 1. Adventure chest selection and chest opening are therefore two separate random stages.

### 3.2 A Wish on Golden Wings event reward

Completing the birthday Special Adventure guarantees:

- one Special Chest;
- 500 base XP;
- +25 Might, +25 Arcana, and +25 Spirit expertise;
- one Music Chest if the remaining collection capacity allows it; and
- one uniformly random relic from Moral Prism, Order Compass, Soul Mirror, and Astral Lens.

Each event-relic option has exactly a 25% chance. This event pool never contains Chronoshard, Wayfinder Sigil, or Twinstar Brooch.

### 3.3 Wayfinder Sigil

The player chooses Mini, Short, or Long and chooses whether to replace a particular offered Adventure or create another one when a slot is available. The Sigil then selects uniformly from every eligible Adventure definition of that chosen kind that:

- is not already offered;
- is not the route being replaced; and
- is not currently active.

The Adventure kind itself is never random because the player chooses it.

Normal timed Mini, Short, and Long offer rotations are deterministic from the time slot. The global Group Adventure offer is also deterministic. They can look varied, but they are not random rolls.

## 4. Trials

### 4.1 Trial offer type

Whenever an empty Trial slot refills, the offered Trial is selected uniformly from Cavern Flight, Ruin Breaker, and Runeweaver. Each has a `1/3` chance per refilled slot. Duplicate Trial kinds may occupy multiple slots.

### 4.2 Trial reward by grade

XP and expertise are fixed by grade. The chest is the random part shown here.

| Grade | XP | Expertise | Chest result |
|---|---:|---:|---|
| D | 10 | +1 | No chest |
| C | 20 | +2 | 100% Wooden |
| B | 30 | +3 | 85% Wooden; 10% Silver; 5% Gold |
| A | 40 | +4 | 30% Wooden; 50% Silver; 20% Gold |
| S | 50 | +5 | 30% Silver; 69% Gold; 1% Dragon |
| S+ | 69 | +7 | 90% Gold; 9% Dragon; 1% Mythical |

Every S+ completion also independently performs:

- a 1% relic roll; and
- a 10% unique Trial-emote roll.

The relic uses the same seven-relic pool and one-time Twinstar Brooch rule described in section 1.3. The emote is selected uniformly from the 25 unowned Trial emotes. If all Trial emotes are owned, the effective emote chance becomes 0%.

The 25 Trial emotes are:

S+ Crown; Perfect Smash; Cavern Soar; Rune Genius; Deep Focus; Victory Roar; Close Call; Speed Blur; Combo Fire; Trial Dizzy; Still Trying; Might Flex; Spirit Wings; Arcana Orbit; New Record; One More Try; Target Lock; Flawless; Training Time; Medal Bite; Power Up; Team Cheer; Trial Zen; Ready!; Champion.

### 4.3 Seven-day Trial constellation

Claiming a completed seven-day streak gives:

- 95% Dragon Chest; or
- 5% Mythical Chest.

The awarded chest is unopened and later uses its normal content rolls.

## 5. Released-dragon daily return system

If there are no released dragons, no daily roll is made.

If at least one released dragon exists:

1. Once per local calendar day there is a 10% chance that a return event is scheduled.
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
- An eligible rare room interaction has a 5% trigger chance, subject to its 12-hour per-dragon cooldown. The eligible dragon is uniform; if furniture-tag interactions match, the interaction is uniform among those matches.
- While a tower room is visibly open, the controllable dragon's purely visual wander check occurs every five seconds. Its move chance is 12% in Deep Night, 20% at Night, 45% at Dusk, 60% at Dawn, 82% in Morning, and 95% during Day or Golden Hour. The visual destination is random within the room's safe movement area.

None of these ambient rolls grant or remove inventory, XP, currency, or expertise.

### 7.4 Jukebox shuffle

When Shuffle is enabled, the selected music tracks are randomly shuffled into a playback queue. With Repeat disabled, playback stops after that queue is exhausted. With Repeat enabled, a new shuffled queue is created for the next cycle. This changes playback order only and has no reward effect.

## 8. Important systems that are not random

- Shop-bought relics are selected directly by the player; they are not mystery purchases.
- Dragon emote packs always contain their ten specified exclusive emotes.
- The Founding Supporter Pack has fixed contents.
- Standard Adventure offer rotations are deterministic by time slot.
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
- `lib/models/profile_portrait.dart`, `lib/models/account_title.dart`, and `lib/models/music_track.dart` — collection pools.
- `lib/models/dragon_emote.dart` — collectible emote pools.
- `lib/screens/trial_game_screen.dart` and `lib/screens/dragon_school_screen.dart` — random challenge layouts.
- `android/app/src/main/kotlin/nl/dragonhaven/app/MainActivity.kt` — native jukebox shuffle.
- `supabase/migrations/202608240007_group_adventure_duration_rules.sql` — authoritative Group Adventure chest roll.

When any of these source tables change, this document must be updated in the same change or release.
