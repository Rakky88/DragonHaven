# DragonHaven online social MVP

Deze fase voegt asynchrone accounts en vriendschappen toe zonder trading of
realtime multiplayer te simuleren.

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

Inventorytabellen geven de mobiele `authenticated` rol geen directe lees- of
schrijfrechten. Nieuwe gameplay- en tradeacties moeten later als gevalideerde
databasecommando's worden toegevoegd. De publieke `social_showcases`-tabel is
bewust alleen een cosmetische projectie voor de friends-UI en mag nooit bewijs
van eigendom zijn voor rewards of trading.

## Backend activeren

1. Maak een Supabase-project en laat e-mail/wachtwoordauthenticatie aanstaan.
2. Pas [de migratie](supabase/migrations/202608240001_online_social_mvp.sql)
   toe met de Supabase CLI of de SQL Editor.
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

## Bewuste grens van deze fase

De lokale save blijft voorlopig de gameplayloop uitvoeren. De eerste online
login importeert inventory exact één keer naar serverobjecten. Bij openen of
verversen van Friends wordt alleen de cosmetische showcase opnieuw gepubliceerd
zodat profielinformatie actueel blijft. Serverinventory wordt niet vanuit de
client overschreven.

Voor trading of gedeelde Group Adventures moet eerst iedere relevante
economiemutatie (chest openen, reward claimen, kopen, egg activeren enzovoort)
naar server-side commando's met idempotency keys en transacties worden verhuisd.
