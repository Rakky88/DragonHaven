# DragonHaven v0.04.03

- Draconomicons now count every discovered dragon form, including Wyrmling and evolved forms, while Dragon families keeps its distinct-family count.
- New and incomplete online accounts repair their profile and wallet automatically; players can resend the account-confirmation email from the sign-in screen.
- Portrait and Title Chests can no longer be traded. The app and server both enforce this, including for older clients and existing offers.
- Portrait and Title Chest shops now show owned/total progress and unopened chest counts.
- Portrait Chest odds show the live chance for every remaining rarity and recalculate after each opening.
- Cosmetic Chest purchases stop once owned rewards plus unopened chests cover the full portrait or title collection.
- All six coin packs and all six gem packs now have their own transparent hand-painted shop sprite, progressing from small piles and pouches to distinct treasure vaults.

Server verification before release: all 18 Supabase migrations matched, database lint returned no errors, and the public Auth health/settings endpoints both returned HTTP 200 with e-mail authentication configured.
