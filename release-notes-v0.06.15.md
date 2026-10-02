# DragonHaven v0.06.15

- Fixes an inventory loading failure that could occur after a Dragon Tower room break expired while a returning visitor was present.
- Canonical inventory reads are now pure and can no longer move a dragon merely because time passed.
- A reconnect requested during an in-flight action now continues after that action fails and safely reconciles the same durable action ID.
- Android keeps probing the real DragonHaven service during network handovers, even when the operating system temporarily reports an unvalidated connection.

Your dragons, inventory, currencies and progress are preserved.
