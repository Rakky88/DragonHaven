# DragonHaven v0.05.01

- Friend cards use a clearer compact layout, keep long titles readable and
  show the discovered-dragon total on one line, including on narrow phones.
- Conclaves now have a more polished Aerie overview, compact navigation,
  clearer member roles and statuses, improved discovery and join cards, and a
  chronological Flight Chronicle presentation.
- Shared achievements in Conclave chat and the Chronicle display their real
  badge, name, description and grouped progress instead of a generic
  "Achievement unlocked" placeholder.
- The Conclave entry is placed directly below the Friends overview so the
  social hierarchy and navigation are easier to understand.
- The tutorial has been expanded to seventeen focused steps covering the
  current Friends, Adventures, Tower, Inventory, Shop, Dragon Academy,
  Conclave, Keeper Journal and account controls, with contextual spotlights.
- A privacy-safe public application-health contract now lets release and
  monitoring gates verify the Supabase gateway, PostgREST and database path
  without reading account or gameplay data.
- Supabase migration 32 adds that read-only health contract. Existing Friend
  Messages, Conclaves, trades, Group Adventures and cloud saves keep their
  existing protected server model.
