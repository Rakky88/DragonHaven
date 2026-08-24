# DragonHaven v0.02.01

## Safe one-for-one trades

- Open a friend's profile and use the gold-rimmed trade sprite to offer one
  Mysterious Egg, chest or relic.
- The offered item is reserved immediately. It cannot be used, discarded,
  opened or offered in another trade while the proposal is active.
- The recipient sees the proposal in the Friends list and receives a local
  notification. Egg proposals include the same mysterious hint shown in the
  Inventory.
- The recipient chooses one Egg, chest or relic in return. The original sender
  then reviews both items and provides the final confirmation.
- Cancelling or rejecting releases both reservations. A completed trade swaps
  both items atomically in the database, so half-completed trades are
  impossible.

## Reliable online inventory

- Tradeable Eggs now retain their complete fixed identity, including lineage,
  alignment, size, incubation time, special variants and XP.
- Completed trades remain claimable per participant until the received item is
  safely stored in the local save. Reconnects and app restarts cannot duplicate
  or lose the settlement.
- All chest types and all three Mystic Relics are supported by the normalized
  server inventory.
