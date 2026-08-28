# DragonHaven v0.04.06

## Collections and Inventory

- Draconomicon `Dragons` now counts every discovered form while `Dragon families` keeps counting lineages.
- My Dragons adds compact list/gallery views, reversible name/date/rarity ordering, combinable form/rarity/Spectral filters and MAX expertise badges at 300.
- Egg and Furniture Inventory tabs add compact list/tile views, reversible logical ordering and contextual filters. Chest Inventory always follows Wooden through Music order.
- Eggs offered to the Rooftop Nest now show their incubation time.

## Music and presentation

- Account Info now links to a persistent Jukebox with per-track toggles, Shuffle and Repeat behavior.
- The catalog contains 80 explicitly CC0/Public Domain recordings. Rêverie was replaced with a verified public-domain file.
- Music Chests cost 250 gems, reveal a new song only when opened and stop being sold when the collection is covered.
- Mythical and Sinister chest sounds are stronger; Sinister includes a clear low evil laugh.
- Currency packs use twelve distinct sprites. New relics have distinct transparent sprites.
- Chinese was fully removed; all new fixed text is complete in the eight remaining languages.

## Relics and chests

- Relic drop chances are Gold 1%, Dragon 2%, Mythical 4% and Sinister 100%; Wooden and Silver never roll relics.
- Added Astral Lens, Chronoshard, Wayfinder Sigil and the unique Twinstar Brooch.
- Twinstar Brooch can move between dragons and doubles XP only for its current wearer. It is unique, permanent and untradeable.
- Chronoshards preserve their fixed 10-90% incubation reduction through Inventory and safe trades.
- Title Chests cost 100 coins and Portrait Chests cost 100 gems. Cosmetic and Music Chests are untradeable and block purchases once all remaining rewards are covered.
- Wooden Chests can no longer contain gems.

## Adventures, Trials and timing

- Solo active Adventures can be aborted without a reward; the dragon becomes available immediately. Group Adventures cannot be aborted.
- Empty Group Adventure creation now shows the same no-available-dragon explanation as other Adventures.
- Adventure notifications are scheduled just after the authoritative return time, preventing early alerts.
- Released dragons now receive one persisted 10% daily return roll at a random local time. No roll is consumed when no released dragons exist.
- Might prominently shows its 30 scoring turns while retaining the smaller miss allowance; final results and rewards wait for the new transitions.
- Arcana has no time limit and can continue indefinitely. Scores from 15 upward remain S+ with the S+ reward; a wrong rune still triggers the red failure beat and delayed spinning result.
- Spirit, Arcana and Might now complete their failure/result animation before granting rewards.

## Starter and online reliability

- Only the Starter Egg can be accelerated by tapping: one second per tap, with its final second always running normally.
- The Starter Egg uses the egg-in-nest art and all egg alignment/morality hints were removed.
- Online startup no longer blocks local play while the first refresh is pending, and network operations fail with a bounded, recoverable timeout message.
- Server trade validation now enforces relic variants and rejects all nontradeable cosmetic/Music chests and the Twinstar Brooch.
