# DragonHaven v0.04.02

- Friend details now show the keeper's achievement total instead of repeating the discovered-dragon count.
- The personal and friend Draconomicons now show both the owned dragon total and discovered dragon-family progress.
- Finished adventures move from Active into a dedicated Completed tab until their rewards are claimed.
- Adventure sections use shorter descriptions and include clear refresh-rule explanations.
- Coin and gem packs now use a compact two-by-three visual grid with increasingly larger piles and chests.
- Account Info is grouped more naturally, with portraits and titles together under Vanity and settings under Preferences.
- Social summary counts are published through a restricted server RPC; achievement identities and private inventory remain hidden.
- Added the public-launch, scaling and cost checklist to the project documentation.

Server verification before release: all 16 Supabase migrations matched, database lint returned no errors, and the public Auth health/settings endpoints both returned HTTP 200 with e-mail authentication configured.
