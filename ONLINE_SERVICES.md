# DragonHaven online social MVP

DragonHaven gebruikt asynchrone online accounts. Er wordt geen realtime
multiplayer gesimuleerd.

## Wat nu is geïmplementeerd

- e-mail/wachtwoordaccounts via Supabase Auth;
- een onveranderlijke, willekeurige Keeper-ID in het formaat `DH-12AB34CD`;
- een publiek profiel met naam, titel en een gekozen portrait;
- vriendschapsverzoeken die pending, accepted, rejected of blocked kunnen zijn;
- blokkeren, deblokkeren en atomair verwijderen uit beide vriendenlijsten;
- een vriendenlijst met portrait, naam, titel en ontdekt-drakenaantal;
- een detailmodal met favoriete draak, level en Might/Arcana/Spirit;
- genormaliseerde servertabellen voor wallet, draken, eieren, kisten en
  afzonderlijke meubelinstanties;
- een eenmalige migratie van de bestaande lokale inventory.
- transactionele 1-op-1 trades met reserveringen, limieten en vervaltijd;
- wereldwijd gelijke, asynchrone Group Adventures;
- een gebundelde online snapshot zodat een refresh niet langer vele losse
  netwerkverzoeken nodig heeft;
- handmatige, versioned cloudback-ups met revisieconflicten en bevestigd
  herstel vanaf een tweede apparaat.
- self-service accountverwijdering na wachtwoordcontrole; het online profiel,
  friendships, trades en de cloudback-up worden door database-cascades gewist.

Inventorytabellen geven de mobiele `authenticated` rol geen directe lees- of
schrijfrechten. Nieuwe gameplay- en tradeacties moeten later als gevalideerde
databasecommando's worden toegevoegd. De publieke `social_showcases`-tabel is
bewust alleen een cosmetische projectie voor de friends-UI en mag nooit bewijs
van eigendom zijn voor rewards of trading.

## Backend activeren

1. Maak een Supabase-project en laat e-mail/wachtwoordauthenticatie aanstaan.
2. Pas alle bestanden in `supabase/migrations` in versievolgorde toe met de
   Supabase CLI.
3. Kopieer `online_config.example.json` naar `online_config.json` en vul de
   Project URL en publishable key uit het Connect-scherm in.
4. Start of bouw Flutter met de configuratie:

   ```powershell
   flutter run --dart-define-from-file=online_config.json
   flutter build apk --release --dart-define-from-file=online_config.json
   ```

`online_config.json` wordt niet door Git gevolgd. Een publishable key hoort in
een mobiele client te mogen staan; beveiliging komt uit grants, RLS en de
gecontroleerde RPC's. Zet nooit een secret/service-role key in de app.

Bij ingeschakelde e-mailbevestiging maakt registratie eerst een account zonder
actieve sessie. De speler bevestigt de e-mail en logt daarna in. Voor lokale
ontwikkeling kan bevestiging tijdelijk in Supabase Auth worden uitgeschakeld.

## Handmatige acceptatiecheck

Gebruik twee verschillende e-mailaccounts en twee apparaten/emulators:

1. Maak beide accounts en noteer beide Keeper-ID's.
2. Verstuur A naar B; controleer outgoing bij A en incoming bij B.
3. Reject een verzoek en controleer dat er bij geen van beide een friendship is.
4. Verstuur opnieuw en accepteer; beide spelers moeten elkaar zien.
5. Open het profiel en controleer portrait, titel, count en favoriete draak.
6. Verwijder A bij B, bevestig de waarschuwing en ververs A; beide lijsten zijn
   leeg.
7. Verstuur opnieuw, block bij B en controleer dat A geen bruikbare informatie
   krijgt over de blokkade.
8. Deblokkeer bij B en controleer dat een nieuw verzoek weer mogelijk is.

## Bewuste beveiligingsgrens

De lokale save blijft de offline gameplayloop uitvoeren. De eerste online login
importeert inventory en latere online verversingen synchroniseren de tradebare
inventory vanuit die lokale bron. Trades zelf worden atomair en met serverlocks
afgehandeld, maar dit maakt de oorsprong van offline verkregen items nog niet
anti-cheatbestendig. De cosmetische showcase blijft uitdrukkelijk geen bewijs
van eigendom.

Voor volledige server-authority moet iedere relevante economiemutatie (chest
openen, reward claimen, kopen, egg activeren enzovoort) later naar server-side
commando's met idempotency keys en transacties worden verhuisd. Cloudback-up is
bedoeld voor herstel en meerdere apparaten, niet als anti-cheatbron.
