# Video Chest activation handoff

Status on 20 September 2026: deferred by the owner. v0.06.00 contains disabled
preview cards under Chests in both shops. It has no ad SDK, reward endpoint,
claim counter or client currency grant. The previews cannot consume a daily
claim. No production database/worker change is required by this release.

## Owner steps

1. Sign in to https://admob.google.com with your own Google account and complete
   publisher and payment information. Do not send passwords or payment details
   in chat. Follow https://support.google.com/admob/answer/7356219 .
2. Add DragonHaven (Android package `nl.dragonhaven.app`). Full serving requires
   a supported app-store listing and Google's readiness review; a GitHub APK
   alone does not satisfy this. See
   https://support.google.com/admob/answer/9989980 .
3. Create two rewarded ad units: `video_chest_gems` (20 gems) and
   `video_chest_coins` (200 coins). Supply only the public app ID and ad-unit IDs
   for integration. Configure appropriate consent/privacy messages in AdMob.

## Implementation required before activation

Integrate Google's Flutter Mobile Ads SDK and consent flow. Keep production
ads off until real IDs and readiness approval are available. Development must
use Google's test ads, never generate test traffic on production units.

The server must issue an account-bound one-use claim nonce, validate Google's
signed server-side verification callback and ad-unit allowlist, and atomically
record the transaction ID, consume the nonce, enforce at most three confirmed
claims per UTC day **per shop**, and credit exactly 20 gems or 200 coins. UTC
reset semantics must be displayed in the final active UI. The user authorizes
three claims independently in each shop. A device clock or client completion
callback must never grant the reward. Callback replay, app restart, second
phone, two concurrent ads, cancellation and a lost response must not duplicate
or lose a verified reward. Use the existing durable server command and
presentation pipeline; return an immediate chest-opening presentation once the
confirmed reward is available. No chest is added to inventory.

Review https://developers.google.com/admob/flutter/ssv before implementing.
Test signed callbacks and all daily-limit/replay boundaries in staging, then
run the repository's mandatory server release preflight before activation.
This document describes pending work, not an implemented security guarantee.
