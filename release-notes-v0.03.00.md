# DragonHaven v0.03.00

## Dragon Trials

- Added a dedicated Trials tab between Available and Active Adventures.
- A random Trial appears at every quarter-hour, up to three waiting Trials,
  and unwanted Trials can be dismissed.
- Added three distinct, animated skill games: Spirit's Cavern Flight, Might's
  Ruin Breaker and Arcana's Runeweaver.
- Spirit subtly shrinks the real flight hitbox, Might widens the successful
  timing zones and Arcana keeps demonstrated runes visible a little longer.
- Trial rewards are driven by player performance from D through S+, with
  coins, XP, expertise points and the requested Chest reward tables.

## Personal records

- Every dragon now keeps an individual best score for all three Trials.
- Account records appear in the Trials overview and friends can inspect both
  account records and the favorite dragon's records.
- Trial records are persisted locally and published as read-only social
  showcase data for signed-in accounts.

## Presentation and reliability

- Added seven purpose-built DragonHaven Trial illustrations, environments and
  a three-frame flight-wing cycle, plus animated grade reveals, responsive
  game HUDs and dragon-stage animations.
- Bundled DragonHaven's public Supabase connection configuration so Online,
  Friends, Group Adventures and Trades work immediately in the official APK.
- Added complete Trial interface translations for every supported language.
- Trial completion consumes its offer once, pays its reward once and returns
  cleanly to the updated Trials list.

Existing local progress and online account data remain intact when updating.
