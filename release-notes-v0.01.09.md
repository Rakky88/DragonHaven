# DragonHaven v0.01.09

## Online keepers and friends

- Create or sign in to a unique e-mail account backed by Supabase.
- Share a stable Keeper ID and send friend requests by ID.
- Accept, reject or block incoming requests and unblock keepers later.
- See each friend's portrait, name, title and discovered-dragon count.
- Open a friend's profile to see their favorite dragon, level and Might,
  Arcana and Spirit expertise.
- Removing a friend requires confirmation and removes the friendship for both
  keepers.
- Existing local inventory is imported once into protected server inventory;
  clients cannot write directly to inventory tables.

## Eggs and Adventures

- The Starter Egg consistently incubates for one hour, including migrated
  older saves.
- The egg countdown uses the compact purple-and-gold `HH : MM : SS` design.
- The egg now sits inside a separate woven nest sprite on onboarding, the
  starter screen, the tower rooftop and the Rooftop Nest detail screen.
- Removed the Mysterious Egg badge, decorative star and “Something is moving
  inside...” overlay from the Starter Egg presentation.
- Active Adventures switch from minutes to live seconds during their final
  minute.
