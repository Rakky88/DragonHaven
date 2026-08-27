# DragonHaven v0.04.04

- The starter egg can now be tapped to remove one extra second per tap, while its final second always hatches naturally.
- The starter Rooftop Nest uses the ornate egg-in-nest artwork from the beginning of the game.
- Group Adventures now show the normal no-dragon message when every dragon is unavailable.
- Title Chests now cost 100 coins and Portrait Chests cost 100 gems.
- Egg clues no longer reveal Moral or Order; only the vague dragon-lineage clue remains.
- The Gems Shop now has a Relics tab between Furniture and Chests. Moral Prisms, Order Compasses and Soul Mirrors cost 500 gems each and can be bought without a limit.
- Shop-bought relics are clearly marked and cannot be traded. Relics earned through gameplay remain tradeable.
- Online accounts now refresh expired sessions before server actions, retry temporary failures and recover from authentication-stream errors.
- Account inventory bootstrap is now idempotent, preventing fresh or restored accounts from being stranded by overlapping setup requests.

Server verification before release: all 19 Supabase migrations matched, database lint returned no errors, and the public Auth health/settings endpoints both returned HTTP 200 with e-mail authentication configured.
