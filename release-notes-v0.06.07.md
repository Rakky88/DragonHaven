# DragonHaven v0.06.07

- Adds optional rewarded ads to the Buy tabs: up to three Free Gems rewards
  of 15 gems and three Free Coins rewards of 150 coins per UTC day.
- Verifies every reward through Google's signed server callback before the
  server adds currency, with one-use claims and duplicate-payment protection.
- Adds Google's advertising privacy choices and an updated DragonHaven privacy
  notice while keeping the rest of the game playable without watching ads.
- Keeps v0.06.06 clients online during the privacy rollout and leaves the ad
  reward switch independently reversible on the server.
- Fixes Android startup with the current Google Mobile Ads SDK by using the
  supported stable WorkManager runtime.
