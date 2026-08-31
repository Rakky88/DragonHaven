# DragonHaven v0.04.16

- Dragon School is now called Dragon Academy throughout the game. A dragon can
  graduate early after completing every lesson with an overall passing result;
  becoming a Dropout still requires using all available retries.
- Sigil Memory and Shadow Match have clearer, more centered layouts. Shadow
  Match also uses stronger contrast and a wider variety of visual differences.
- Background music now stops whenever DragonHaven leaves the foreground and
  resumes only after the app becomes active again.
- My Dragons and Eggs remember the selected tile/list view, ordering and sort
  direction between sessions.
- Badges are now selectable Vanity items. The selected badge appears on the
  account portrait and is shared visibly with friends alongside the selected
  portrait frame.
- The Founding Supporter furniture set can be placed in Tower rooms. Its portrait
  frame now surrounds portraits without distorting or covering them.
- The Packs page remains stable when reopened, including for accounts that own
  the Founding Supporter Pack.
- Music Chests now use their own opened-chest artwork instead of sharing the
  Portrait Chest result image.
- Online Friends refreshes keep a valid server snapshot visible even when a
  non-critical inventory, showcase, reservation or notification-maintenance
  action fails. This prevents the misleading empty Friends screen reported for
  an otherwise healthy account.
- The Friends navigation tab now shows a compact red count badge whenever there
  are incoming friend requests.
- Save schema 48 preserves the new view preferences and Vanity selection.
- Supabase migration 29 adds backward-compatible online badge profiles. The
  existing three- and four-parameter profile update calls remain available for
  older app versions during rollout.
