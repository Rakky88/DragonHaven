# DragonHaven v0.06.10

- Adds Spirit Alignment, Ruin Guard and Rune Orbit to the standard Trial
  rotation, with their own records and rankings. Matching Ascended dragons
  unlock their specialist Trial; Mastery dragons unlock all three.
- Keeps the original Trials open to every available dragon. Ordinary draws
  choose Arcana, Spirit or Might evenly (or those three plus Event evenly while
  an event is active). After a focus is selected, an owned matching Ascended or
  Mastery dragon gives an even chance of the original or Ascended Trial; busy
  owned dragons still unlock it.
- Marks Ascended Trial cards clearly and silently refills the Trial board once
  per elapsed fifteen-minute boundary, including after returning to the app or
  finishing a Trial that crossed the boundary.
- Grants the final evolution Expertise gift automatically: +10 to its chosen
  Expertise, or +5 Might, Arcana and Spirit for Mastery.
- Restores the livelier tower-room view, safer room changes, working dragon
  clearing, complete decoration placement information and improved furniture
  framing.
- Enables the approved rewarded-ad foundation for Free Gems and Free Coins,
  with server-verified, exactly-once rewards and a three-per-day limit.
- Makes inventory actions recover automatically when a server reply is slow,
  while preserving the same request so rewards and costs can never duplicate.
- Keeps the current game screen open across brief Wi-Fi/mobile handovers and
  app resumes instead of rebuilding the account and navigation flow.
- Prevents routine server confirmation from hiding already confirmed inventory
  and only blocks further changes while an uncertain action is reconciled.
- Adds a bounded game-worker response time and safe lease handoff so reconnects
  no longer wait behind an abandoned sixty-second command lease.
- Reduces the routine account-status heartbeat from every ten seconds to once
  per minute while keeping connectivity-return recovery immediate.
- Correctly handles privacy confirmation without treating a signed-in account
  as logged out.
- Prevents the signed-in Keeper from appearing as blocked and repairs the rare
  egg return/hatch state that could leave the game waiting at progress checks.
