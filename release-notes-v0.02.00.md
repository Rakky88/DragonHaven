# DragonHaven v0.02.00

## One identity everywhere

- A verified online account now automatically uses the name, portrait and
  title selected in the offline account. There is no separate online identity
  to maintain.
- Friends and Group Adventure participants display their real selected
  portrait and localized title.

## Asynchronous Group Adventures

- Group Adventures require a verified online account and use authoritative
  server lobbies for two to four connected keepers.
- Everyone sees the same global Group Adventure at the same moment. The offer
  refreshes on Sunday at noon in Europe/Amsterdam.
- Start a lobby or join a friend's lobby with one available dragon. Before the
  journey begins, participants can withdraw and the starter can remove them.
- The journey starts automatically at the required participant count once all
  combined level and expertise requirements are met.
- Started journeys persist through the weekly refresh and their rewards remain
  claimable. Waiting lobbies expire when the global offer refreshes.
- An account can participate in a weekly Group Adventure only once, regardless
  of which dragon it uses. If the same Adventure ID returns in a later week, it
  can be played again.

## Authoritative rewards

- Group timers, participants, eligibility and rewards are calculated by the
  database. Group duration is reduced by the participants' combined matching
  expertise in minutes.
- Group rewards are applied idempotently to both the local save and the online
  inventory, preventing duplicate claims after retries or reconnects.
