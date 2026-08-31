# DragonHaven support- en privacyprocedures

Laatst bijgewerkt: **31 augustus 2026**  
Uitgangsversie: **v0.05.01 / productieschema 32 / kandidaat-schema 33 op staging bewezen**

## Doel en grens

Dit document beschrijft de huidige minimale supportwerkwijze zonder betaalde
supporttool. Het is een technisch en operationeel concept, geen juridisch advies
of definitieve privacyverklaring. Rick blijft verantwoordelijk voor het publieke
supportadres, reactietijden, juridische bewaarplichten en de uiteindelijke
privacy-/Data Safety-tekst.

Support verandert productiegegevens nooit alleen op basis van een zichtbare
keepernaam, screenshot of e-mailafzender. Een onderzoek begint met Keeper ID,
UTC-tijdvenster, appversie, functie, supportcode en—alleen wanneer nodig—de
privacyarme export uit **Account Info → Copy support diagnostics**.

## Minimale intake

Vraag alleen om:

- Keeper ID in het formaat `DH-XXXXXXXX`;
- UTC-datum/tijd en betrokken functie;
- appversie en Androidversie;
- achttekens-supportcode;
- korte beschrijving van verwacht en werkelijk gedrag;
- eventueel de ingebouwde supportexport via een vooraf afgesproken veilig kanaal.

Vraag nooit om wachtwoord, access-/refresh-token, volledige save, volledige
inventory, database-export, betaalkaartgegevens of een service-role key. Neem
geen zichtbare keepernaam op wanneer Keeper ID voldoende is. Bewaar een
privacyarme supportexport maximaal zeven dagen; incidentbewijs zonder
persoonsgegevens maximaal dertig dagen.

## Onderzoeksroute

1. Classificeer het verzoek volgens `INCIDENT_RUNBOOK.md` en noteer een interne
   willekeurige incident-ID.
2. Controleer publieke Auth- en applicatiehealth. Een brede storing gaat vóór
   accountspecifiek onderzoek.
3. Zoek uitsluitend op Keeper ID en controleer dat precies één profiel bestaat.
   Gebruik de zichtbare naam nooit als identifier.
4. Koppel supportcode aan de volledige correlation ID uit de door de speler
   aangeleverde supportexport. DragonHaven bewaart deze client-events momenteel
   alleen begrensd in het appgeheugen; beweer niet dat de server een ontbrekende
   correlation ID kan reconstrueren.
5. Beperk eventuele Supabase-logzoekopdracht tot het kleinste UTC-venster en de
   noodzakelijke vaste operatie-/foutcode. Kopieer geen requestbody of save.
6. Leg conclusie, noodzakelijke herstelactie, toestemming en verificatie vast.
7. Verwijder de supportexport uiterlijk na zeven dagen en privacyarm
   incidentbewijs uiterlijk na dertig dagen.

Migratie 33 bouwt een least-privilege supportlookup met inzagelog en is op het
geïsoleerde stagingproject toegepast en door lint/preflight bewezen. Tot deze
RPC later afzonderlijk voor productie is goedgekeurd, blijft directe
productie-inzage een uitzonderlijke handeling met expliciete toestemming. De
RPC accepteert uitsluitend een service-role caller,
een vaste reden, operatoralias en casusnummer. Hij retourneert geen e-mail,
display name, inventory, savebody, tegenpartij of itemdetails.

De lokaal gebouwde `staging-support-privacy.yml` maakt deze grens toetsbaar
zonder een service-role key als repositorysecret toe te voegen. Na exacte
handmatige bevestiging controleert de stagingflow dat een gewone ingelogde
sessie wordt geweigerd, bootst hij de service-role-context alleen binnen de
afgeschermde managementquery na, valideert hij de minimale response en het
30-dagen-inzagelog, en verwijdert hij een speciaal aangemaakte verlopen
testsentinel via de echte cleanupfunctie. Het bewijsbestand bevat uitsluitend
booleans, termijnmetadata en een UTC-tijdstip; geen Keeper ID, UUID, e-mail,
token, wachtwoord of responsebody. De workflow is nog niet naar `main` gepusht
of live op staging uitgevoerd.

## Procedures per veelvoorkomend verzoek

### Verloren account of nieuw toestel

1. Laat de speler via de normale Supabase Auth-route inloggen of een
   wachtwoordreset aanvragen; support vraagt nooit om het oude wachtwoord.
2. Controleer bevestigde e-mailstatus en Keeper ID, niet alleen de zichtbare naam.
3. Laat de speler cloudmetadata bekijken vóór een restore.
4. Herstel geen save handmatig zonder doelrevision, lokale recovery copy en
   expliciete keuze van de speler.
5. Wanneer eigendom niet betrouwbaar vaststaat, stop; ken geen account of items
   toe op basis van screenshots.

### Bevestigings- of resetmail niet ontvangen

1. Controleer Auth health, projectstatus en relevante provider-/Auth-logs in het
   kleinste tijdvenster.
2. Laat de speler spelling, spammap en eventuele providervertraging controleren.
3. Gebruik uitsluitend de ingebouwde resend-route. Deel of kopieer geen
   bevestigingstoken.
4. Wijzig `email_confirmed_at` niet handmatig op productie.

### Mislukte trade

1. Verzamel beide Keeper IDs, trade-ID indien zichtbaar, UTC-tijd en supportcode.
2. Controleer serverstatus, deelnemers, status, reserveringen en timestamps.
3. Na een clienttimeout eerst refreshen: een atomaire serveractie kan al zijn
   afgerond. Voer geen tweede grant of losse inventory-update uit.
4. Alleen een vooraf geteste, idempotente correctie mag na expliciete
   productietoestemming worden uitgevoerd.

### Back-upconflict of verkeerde restore

1. Vergelijk lokale basisrevision met huidige serverrevision en de maximaal vijf
   beschikbare revisiemetadata.
2. Gebruik **Keep local for now**, **Restore cloud** of de dubbel bevestigde
   **Replace cloud**-route; maak altijd eerst een lokale recovery copy.
3. Controleer dat de vorige cloudkopie in de dertigdagengeschiedenis staat.
4. Een toekomstige server-owned economie mag nooit door een oude save worden
   teruggedraaid; dit blijft afhankelijk van auditfase 4.

### Accountverwijdering

1. De speler gebruikt de self-service knop en voert opnieuw het wachtwoord in.
2. `delete_my_account()` verwijdert de Auth-user. Profiel, saves, inventory,
   sociale relaties, messages en accountgebonden audit-/herstelrecords cascaderen
   mee volgens de database-FK's.
3. Support verwijdert een account niet op basis van alleen een e-mail of naam.
4. Na verwijdering worden resterende provider-/supportrecords volgens hun eigen
   vastgelegde termijn verwijderd. Een wettelijke uitzondering moet vóór
   bewaring worden gedocumenteerd; die bestaat nu niet voor live aankopen, want
   Google Play Billing is uitgeschakeld.

### Refund of aankoopprobleem

Echte Google Play-aankopen staan nog uit. Support kent daarom geen gems of een
Supporter Pack toe op basis van een betaalbewijs of screenshot. Zodra Billing
later wordt geactiveerd, zijn servervalidatie, purchase token, acknowledgement,
refund en revocation uit auditfase 5 verplicht. Tot die tijd wordt ieder gemeld
echt aankoopbedrag als potentieel incident onderzocht.

### Vermoed misbruik

1. Leg alleen objectieve vaste foutcodes, requestfrequenties, timestamps en
   betrokken server-ID's vast.
2. Blokkeer of verwijder niet automatisch op basis van één afwijking.
3. Bewaar geen complete chat-, save- of inventorykopie “voor de zekerheid”.
4. Escalatie of tijdelijke blokkade vereist een later vastgesteld misbruikbeleid
   en menselijke beoordeling.

## Huidige bewaarmatrix

| Gegevens | Huidige technische termijn | Verwijderpad | Status/actie |
| --- | --- | --- | --- |
| Lokale diagnostische events | Maximaal 100 events in geheugen; verdwijnen bij proces/eigen buffer | Appproces/buffer | Klaar; geen e-mail, token, save of inventory |
| Door speler gedeelde supportexport | Operationele afspraak maximaal 7 dagen | Handmatig door supporteigenaar | Rick moet veilig kanaal en verwijdercontrole kiezen |
| Privacyarm incidentbewijs | Maximaal 30 dagen | GitHub-artifactexpiry/handmatige casuscleanup | Klaar voor huidige workflows; geen spelerdata in artifacts |
| Friend- en Conclave-chat | 24 uur | Vijfminuten-Cron plus opportunistische cleanup | Servermatig afgedwongen |
| Conclave-invites | Tot `expires_at` (7 dagen) | Dezelfde vijfminuten-cleanup | Servermatig afgedwongen |
| Huidige cloudsave | Tot vervanging of accountverwijdering | Self-service accountdelete/cascade | Nodig voor dienst |
| Vorige cloudrevisies | Maximaal 4 vorige en maximaal 30 dagen | Dagelijkse cleanup plus accountdelete/cascade | Servermatig afgedwongen |
| Private pre-import recovery | Maximaal 30 dagen | Accountdelete/cascade; migratie 33 voegt dagelijkse fysieke purge toe | Op staging bewezen; productie-uitrol nog apart goedkeuren |
| Privacyarm import-auditrapport | Tot accountverwijdering | Accountdelete/cascade | Nodig voor eenmaligheid en herstelbewijs |
| Supportinzagelog | Maximaal 30 dagen; alleen hash van Keeper ID, interne UUID, operatoralias, casusnummer en vaste reden | Migratie 33: dagelijkse purge; accountdelete anonimiseert de doel-UUID | Op staging bewezen; geen e-mail, naam, save of inventory |
| Profiel, serverinventory en sociale relaties | Tot accountverwijdering | `delete_my_account()` en FK-cascades | Self-service aanwezig |
| Sociale notificatie-inbox | Momenteel tot accountverwijdering; friend-message events volgen 24-uursmessagecleanup | Accountdelete; gedeeltelijke messagecleanup | **Open gat:** kies termijn voor acknowledged en oude unacknowledged events vóór migratie |
| Conclave Chronicle | Zolang de Conclave bestaat; actor-ID wordt null bij accountdelete | Conclave-dissolve/cascades | Publieke groepshistorie; definitieve termijn en privacytekst nog kiezen |
| Firebase Crashlytics/Performance | Nog niet actief; beoogde providertermijnen circa 90/30–60 dagen | Providerbeleid | Wacht op Firebase-config en privacybeoordeling |
| Aankoopadministratie | Niet actief | Niet van toepassing | Termijn pas vóór Billing kiezen met wettelijke/fiscale beoordeling |

## Least privilege en toegang

- De app gebruikt alleen anon/publishable en ingelogde gebruikerssessies; nooit
  service-role of managementtokens.
- Productie-managementtoegang blijft bij Rick en gecontroleerde technische
  werkzaamheden totdat rollen en een supporttool bestaan.
- De op staging bewezen kandidaat-supportlookup retourneert alleen interne user UUID,
  accountstatus, saveversie, noodzakelijke timestamps en geaggregeerde
  back-up-/tradestatus. Geen e-mail, display name, inventory of savebody.
- Iedere lookup vereist operatoralias, vaste reden en casusnummer en schrijft
  eerst een append-only inzagelog met een technisch afgedwongen termijn van
  dertig dagen. Keeper ID staat daarin uitsluitend als SHA-256-hash.
- Correlation IDs blijven client-side en worden alleen uit de door de speler
  gedeelde privacyarme supportexport gehaald; de serverlookup beweert expliciet
  niet dat hij ontbrekende IDs kan reconstrueren.
- Toegang wordt direct ingetrokken wanneer een beheerder die taak niet meer
  uitvoert.

## Nog te besluiten of bouwen

### Door Codex

- De service-role-only supportlookup met append-only inzagelog uit migratie 33
  via de lokaal gebouwde production-blocked workflow op staging testen en pas
  daarna afzonderlijk voor productie laten goedkeuren.
- De dagelijkse fysieke purge voor verlopen private pre-import recoverycopies
  is op staging toegepast; vóór productie de testsupportcasus en het
  productievenster afzonderlijk goedkeuren.
- Na Ricks termijnkeuze acknowledged en oude unacknowledged sociale notificaties
  automatisch opruimen.
- De lokaal gebouwde privacyarme testsupportmelding na expliciete push- en
  stagingtoestemming uitvoeren en het bewijs registreren.
- Verwijder-/retentie-E2E herhalen nadat server-owned economie en Billing bestaan.

### Door Rick

- Expliciet toestemming geven om de testsupportworkflow naar `main` te pushen
  en uitsluitend op staging uit te voeren; hiervoor zijn geen nieuwe secrets of
  betaalde diensten nodig.
- Publiek supportadres, verantwoordelijke personen en haalbare reactietijden
  kiezen.
- Definitieve privacyverklaring, accountverwijderpagina en Data Safety-invoer
  juridisch/inhoudelijk controleren.
- Termijn kiezen voor sociale notificaties en Conclave Chronicle.
- Bepalen wie productiegegevens mag zien en toegang periodiek controleren.

Zonder deze laatste keuzes blijft de huidige self-service verwijdering werken,
maar is fase 6 nog niet gereed voor een brede publieke Play Store-lancering.
