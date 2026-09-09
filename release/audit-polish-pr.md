Prepare server-owned chest opening and furniture/relic purchases so a retry returns the same stored outcome. Migrations 45–47 add private drop rolls, durable receipts, ownership checks and a legacy inventory upload guard. The broader economy stays disabled; production is still on schema 44.

The Altar now has its own Inventory tab, reviews egg details before selection, puts Nameweaver’s Quill first and uses a stable altar composition with a continuous return animation. Trials have a compact header, six distinct painted Arcana pumpkins and a complete Might lantern silhouette.

The staging load workflow can create temporary confirmed synthetic accounts without mail, remove only its own accounts and require every user to log in and bootstrap before a run can pass. The 1000-user stage requires a passing 100-user baseline on the same schema.

Validation: 501 Flutter tests passed, Dart analysis is clean, reference documents are synchronized, and the 320×640 UI/animation captures were inspected. Staging migration 47 passed parity, zero-error lint, health and rollback contracts in run 34111166461. The synthetic transport/cleanup contract also passes. Live run 34115250094 created and removed all 100 synthetic accounts: 59 logged in and bootstrapped, while 41 logins hit Auth HTTP 429. All 702 read RPCs succeeded (snapshot p95/p99 319/336 ms); post-load health and parity passed. The 1000-user gate correctly stayed closed. This does not establish capacity for 100 active users; the next load design must separate session warm-up from login bursts without weakening Auth protection.

No version bump, production deployment or economy activation is included.
