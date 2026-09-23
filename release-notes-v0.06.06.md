# DragonHaven v0.06.06

- Restores more of the v0.05.40 Tower flow: room changes live inside a floor,
  floor controls are aligned cleanly, and My Dragons can sort by dragon type.
- Restores the compact Adventure details and actions, including clear expertise
  gain and loss indicators in both the list and detail views.
- Fixes the sign-out/sign-in recovery loop so a valid session can load the
  server-owned collection again without getting stuck on the progress screen.
- Makes notification access in Account Info visible and actionable. Granting
  access immediately refreshes scheduled reminders and push registration.
- Routes Android and Firebase notifications through the same stable channel and
  keeps social events retryable when the device could not display them.
- Keeps all progress, rewards and hidden outcomes server-owned, with optimistic
  previews still rolling back when the server refuses an action.
