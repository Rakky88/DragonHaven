# DragonHaven v0.06.10

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
