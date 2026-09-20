# Server-owned gameplay completion

Started 20 September 2026 from released v0.05.41 (1544dfe).
User objective: a new phone or reinstall only requires signing in to recover
all confirmed account progress, with no stale local device able to overwrite it.

The user explicitly requires all of the following to follow the account:

| Account data | Restoration invariant |
| --- | --- |
| Dragons | All owned identities, form, sex, fixed hidden properties, XP, expertise, school history, records, highlights, name, favorite, location, needs and equipment |
| Eggs | Nest/stash identity, original incubation deadline, fixed genetics, revelations, tags and tag revisions |
| Adventures/trials | Active solo/group/pair journey, reservation, original deadlines, reward-claim history, records and recoverable trial attempt |
| Tower | All floors, room choices, order, damage/ward and exact furniture placements |
| Inventory | Coins/gems, chests, special chests, relic quantities, rolled Chronoshards, tradeability, equipment and trade reservations |
| Altar | Shell Fragments, Draconic Essence, Weavehearts, crafted relics, consumed-egg history and pending receipts |
| Collection | Music, portraits, frames, titles, badges, emotes, packs, discoveries, achievements and each current selection |
| Preferences/history | Language, jukebox selections/settings, display preferences, notification choices, tutorial, journal and acknowledged reveals |
| Social/purchases | Same account relationships, Conclave, chats/read markers, trades and verified purchases; never imported from another device's local account |

Only installation credentials, push tokens and operating-system permissions are
device-specific. They must not overwrite account preferences on a new device.

## Completion gates

- [x] Complete public account preferences/onboarding and their validated commands.
- [x] Connect the production shell, account/social features and all gameplay
  screens to authoritative reads/commands, preserving the existing game content.
- [x] Automatically restore a sole cloud source; retain explicit reconciliation
  for genuinely conflicting legacy saves and preserve original recovery copies.
- [x] Finish fresh-account initialization and lossless legacy migration with a
  compatible-client gate. Old clients must not enter or overwrite migrated play.
- [x] Verify current rules/worker parity, all domain tests and real staging
  migration, two-device, reinstall, interrupted-reply and recovery scenarios.
- [x] Deploy the verified compatible server package with controlled activation,
  health checks, evidence and a rollback path that cannot duplicate assets.

Production is active on schema 92 for v0.05.42 / build 10092 and newer compatible
clients. The signed public APK was verified before enabling commands and
migration with the exact reviewed worker hash. All shadow switches remain off.
Each existing account transfers when the compatible client opens; no operator
bulk-converted or edited real player accounts. Keep the old installation until
that first protected transfer has completed.

## Completed verification

- Both fresh and legacy synthetic staging accounts survive a new authentication
  session with an identical full public projection and private state hash.
  This includes Altar balances (817/36/4), five Astral Lenses with two untradeable,
  tagged eggs, exact dragon high scores, original adventure deadlines and unknown
  future metadata. Replayed initialization/migration/commands do not duplicate
  inventory. The old device cannot overwrite a newer confirmed revision.
- Two empty client directories restore the complete rich fixture, including
  furniture coordinates, purchased packs, selected profile decorations and
  jukebox choices. Normal AccountStartupApp also opens two empty installations
  directly into ServerDragonHavenApp without a local save or import.
- Staging migrations 89-92 are applied. All four SQL contracts and targeted function
  lint pass. Production rehearsal passed and rolled back at schema 88, then schema 92
  was applied without changing authority. Mandatory full database lint and
  public health checks passed before publication.
- Confirmed identity/cosmetic/achievement fields project atomically to social
  profiles. Conclave achievements only publish IDs present in server progress.
  Read receipts are private, membership-checked and deleted with expired messages.
- Source saves, fixed egg properties and original timers survive the migration.
  A genuine legacy local/cloud conflict still requires selecting a source; the
  implementation never guesses by adding two inventories together.
- The public release asset matches the signed APK byte-for-byte by GitHub's
  SHA-256 digest. Production initialization replay, onboarding and second-login
  restoration passed using one marked synthetic account, which was removed.
  Post-activation preflight at **2026-09-20 16:04:19 UTC** reports 92 matching
  migrations, zero database lint errors and HTTP 200 for all health endpoints.
  See [RELEASE_V0.05.42_VERIFICATION.md](RELEASE_V0.05.42_VERIFICATION.md).

## Rollout and recovery procedure

1. Build/test the exact client and worker; retain their hashes. Rehearse using
   `tool/server_account_cutover.py --environment production --phase rehearse`.
2. Apply the reviewed additive migrations with the same tool and `--phase apply`.
   This step cannot enable authority. Deploy the verified worker with all five
   switches still off; run the mandatory release server preflight.
3. Publish/install the compatible signed client, then set the minimum client
   build, exact worker hash and only `enabled` + `migration_enabled`. Keep all
   shadow switches off. Old apps never enter the new handoff.
4. Each compatible account seals/uploads its final legacy state, captures it,
   imports through shared server rules and atomically activates. Reinstallations
   read active authority before considering any device progress.
5. On an incident, disable migration to stop new conversions. If command safety
   is uncertain also disable the worker's mutation switch. Preserve canonical
   state and receipts, deploy the repaired verified worker and resume; never
   convert an active account back to its stale legacy save.
