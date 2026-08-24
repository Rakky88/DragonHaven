# DragonHaven v0.01.10

## Verified accounts

- New online accounts must confirm their unique e-mail address before signing
  in. The e-mail address remains private and is never shown to other players.
- DragonHaven now also rejects any unverified Supabase session in the client.

## Expertise mastery

- Might, Arcana and Spirit are each capped at 300 per dragon, including older
  saves that previously exceeded the cap.
- Added **Master of All Three**, awarded when one dragon reaches 300 in all
  three expertises.

## Adventure balance

- Mini Adventures now advertise 6 to 15 minutes and Short Adventures 6 to 8
  hours. XP and expertise rewards scale upward when an adventure was lengthened.
- Mini duration is reduced by the matching expertise in seconds.
- Short duration is reduced by the matching expertise in minutes.
- Long and Group duration is reduced by the participating dragons' combined
  matching expertise in minutes.
- The adjusted duration is applied immediately to the normal countdown without
  displaying a separate modifier.
