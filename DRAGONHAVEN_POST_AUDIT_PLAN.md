# DragonHaven verbeterplan na audit v0.04.06

Laatst bijgewerkt: **9 september 2026**
Technische uitgangsversie: **v0.04.06**

## Correctierelease v0.05.24 in uitvoering

De Special Adventure-drakenkeuze gebruikte na v0.05.23 nog de enkele focus.
De gedeelde keuzelijst toont nu alle drie scores en markeringen, vereist alle
drie highlights voor de gemarkeerde groep en sorteert op hun som. Dit geldt
ook voor verjaardag en het accepteren van een Valentijn-uitnodiging.
Zes eventregressies en de bestaande keuzelijstcontroles slagen (17 tests).
Gewone Adventures houden hun enkele focus; serverregels en beloningen wijzigen
niet. Releasebewijs: `RELEASE_V0.05.24_VERIFICATION.md`.

## Eventrelease v0.05.23 afgerond

Op verzoek krijgen de vier overige seizoensproeven eigen spelmechanieken;
Halloween blijft behouden. Eventstop, initiële trialvulling, drie-expertisekeuze,
leesbare timer/chatknoppen, toren-/academieafbeeldingen, roze Valentijn en eigen
Jingle Bells-uitvoering zijn gebouwd. De regelproeven (500 doolhoven en 500
prismapuzzels), schermbediening, documentatieguard en analyse slagen.
Stagingrun 34326484098 slaagt inclusief echte client-/serverstromen en opruiming.
Productie staat op schema 60: lint 0 en alle healthchecks HTTP 200; spelereconomie
blijft legacy, met nul schaduwstaten en uitgeschakelde economische mutaties.
Ook onontdekte Draconomicon-families en vormen krijgen lichtere achtergronden,
zodat silhouetten tijdens events goed zichtbaar blijven. Acht bestaande controles
op vormen, grenzen, vergrendeling en documentatie slagen.
De dubbele beschikbaarheidstimer is uit compacte Special-adventurekaarten
verwijderd; de eventbalk en de volledige details houden hun timer. De bestaande
scherm-/documentatiecontrole slaagt met 19 tests. Draconomicon-overzicht en
uitgeklapte silhouetten zijn ook op Android visueel gecontroleerd.
Release v0.05.23 / 10073 is op 9 september om 08:41:57 UTC gepubliceerd.
De definitieve bron `8fa616a8a8f18b7b0f6196eaa4ee795b0ba65299` slaagt in
releaseworkflow 34329479535 met 689 tests, analyse en ondertekeningscontrole.
De APK is als update op Android gecontroleerd met behoud van spelvoortgang;
taalkeuze blijft na herstart bewaard. Download, bestandshash en vaste latest-link
zijn geverifieerd. Productiecontrole na publicatie om 08:42:22 UTC: schema 60,
lint 0, alle healthchecks HTTP 200 en economische mutaties uitgeschakeld.
Definitieve releasebewijzen: `RELEASE_V0.05.23_VERIFICATION.md`.
De onderstaande servereconomie-deelstappen blijven afzonderlijk afgebakend.

## Hervatte servereconomie: ei-, Altar- en drakenacties

De volgende stagingkoppeling is gebouwd: ei-details met filters, taggen,
broeden/uitkomen, Chronoshards, Altar-return/crafting/onthullen en drakennamen,
uitrusting, evolutie en vrijlaten. De schermen gebruiken alleen de openbare
serverweergave en de duurzame actiesessie. Verloren antwoorden en accountwissels
kunnen geen tweede beloning of afschrijving veroorzaken. Stagingrun 34286596835
op bron `29c2519` slaagt: schone analyse, 663 tests, domeinpariteit, SQL-contracten
en echte schermacties. Daarna zijn de synthetische accounts opgeruimd en de worker
uitgezet; schema 59, lint 0 en alle health-endpoints HTTP 200 om 22:41:02 UTC.
Bewijs en afbakening: `SERVER_ECONOMY_UI_VERIFICATION.md`.
Dit blijft een deelstap: volledige gameplay, trialvalidatie, sociale afwikkeling,
migratie en activatie staan nog open; versie en productie-economie wijzigen niet.

De volgende deelstap koppelt gewone Mini/Short/Long Adventures en Wayfinder aan
dezelfde serversessie: starten, afbreken, claimen, vervangen en verversen. De
actieve lijst sorteert op eindtijd; de drakenkeuze gebruikt openbare expertises
en opent de bestaande Draconomicon zonder lokale spelprovider. Vier extra
regeltests en twee schermtests slagen. Stagingrun 34289398487 op `33d4fc5` slaagt
met alle 669 tests, domeinpariteit, een echt afgewachte serverdeadline, weigering
van een vroege claim en precies één beloning na een verloren claimantwoord.
Opruiming en healthcontrole slagen om 23:19:28 UTC; schema 59, lint 0, HTTP 200.

De volgende woningdeelstap is gebouwd: kamers ontgrendelen/selecteren,
verdiepingen kopen, opgeslagen reparatieprijzen en ward-upgrades. De lokale
regel- en schermproeven controleren exacte kosten, verloren antwoorden,
bevestigingen en grote Nederlandse tekst. Stagingrun 34290527414 op `a53fb50`
slaagt met alle 675 tests, domeinpariteit, contracten en echte schermacties.
Na opruiming: schema 59, lint 0 en HTTP 200 om 23:33:58 UTC.
Ook drakenvoorkeuren hebben nu een expliciete serveropdracht: zet een highlight
aan/uit of kies één favoriet. Herhaalde opdrachten draaien een highlight niet
terug en tellen een favorietkeuze niet nogmaals. Regel-/schermtests en visuele
controle slagen. De echte netwerkproef 34291657311 op `32817ed` slaagt ook:
679 Fluttertests, 15 Edge-tests, domeinpariteit en alle schermproeven opnieuw
groen. Testaccounts/schaduwdata zijn opgeruimd en de worker is uitgeschakeld;
schema 59, lint 0 en HTTP 200 om 23:49:09 UTC. Een onafhankelijke productiecheck
gaf om 23:42:42 UTC HTTP 200 voor Auth/settings/app. Seasonal/group-afwikkeling,
trialvalidatie, meubelbewerking, serverdaggrenzen en productiemigratie blijven
afzonderlijk open; dit is geen volledige afronding of activatie van de economie.

## Uitgebracht: v0.05.22 (10072): broches, events en expertise-uitlijning

De tussentijdse spelerswensen zijn gebouwd: Gender alleen als derde detailrij,
verticaal gecentreerde Expertises, drie nieuwe broches met één gedeelde plek per
draak, de 10:1 dropweging, Halloween S+ vanaf 2500 en uitgebreidere eventthema’s.
Nieuwe persoonlijke events vervangen het vorige event; bestaande runs houden
hun herkomst. Migraties 58/59 zijn eerst met rollback op staging gecontroleerd.
Volledige releaseverificatie en uitrolstatus: `EQUIPMENT_AND_EVENT_VERIFICATION.md`.
Releaseworkflow 34281504522 slaagt met schone analyse, 652 tests, productie-
preflight en ondertekende AAB. De geïnstalleerde APK, GitHub-digest en vaste
latest-download zijn geverifieerd; ook de controle na publicatie slaagt.
Bron: `0a736c9075d3e3d06cf54ad35882d32509fe68d7`.
Bewijs: `RELEASE_V0.05.22_VERIFICATION.md`.
De winkel/serverkoppeling hieronder blijft uitsluitend in de expliciete staging-
build; deze release activeert geen volledige servereconomie voor spelers.

## Hervatte audit na v0.05.21: winkel en inventaris aan de server

Binnen de gegeven toestemming is de volgende koppeling gebouwd: de bestaande
meubel-/reliek-/vanitywinkel en kistanimatie kunnen dezelfde duurzame serversessie
gebruiken. Dit werkt via een expliciete stagingbuild vóór het laden van lokale
spelgegevens. Ontbrekende serverinformatie valt nooit terug op een lokale wallet.
Dubbele taps, verloren antwoorden, herstart, achtergrond en accountwissel zijn
lokaal getest met echte spelregels en schermen. Een mislukte kistopening heeft
nu een sluitbare foutmelding. Grote Nederlandse tekst past in de verbindingsstatus;
de winkeltabs kunnen bij grote tekst horizontaal schuiven.
Bewijs en stagingstatus: `SERVER_ECONOMY_UI_VERIFICATION.md`.

De nieuwste release is v0.05.22 / 10072. Productie en staging staan op schema
59; de volledige servereconomie is niet geactiveerd. De echte winkel- en
kistproef op staging slaagt. Volledige gameplaykoppeling, trialvalidatie, sociale afwikkeling en
de gecontroleerde migratie van spelers blijven open. Het checklistoverzicht is
ook gecorrigeerd: Firebase is al ingericht en bewezen; dat is geen ontbrekende
accountactie meer. Een representatieve meetperiode en privacy-/storeverklaringen
blijven afzonderlijke acceptatiepunten.

## Uitgebracht: v0.05.21 (10071), 8 september 2026

- Geselecteerde Expertises laten de bestaande sprite oplichten; ster en gele
  rijmarkering zijn verwijderd. Dezelfde gloed verschijnt in beide infovensters.
- Zes volledige eventlogo's op basis van het originele logo, gebruikt in de app
  en als Android-starticoon. Lokale kalender en terugschakeling naar het gewone
  icoon; geen serverwijziging of betaalde dienst.
- Bestaande Draconomicon-sprite als compacte knop naast beide kiestitels,
  met toegankelijk label en behoud van de selectie bij teruggaan.
- Jaarlijkse nieuwjaarsvensters blijven na 1 januari actief tot hun bestaande
  eindtijd. Geen verandering aan eventdatums, beloningen of previewrechten.

Verificatie en platformgrenzen: `EVENT_BRANDING_VERIFICATION.md`.
Appversie, updatevergelijking en Android-buildnummer zijn een stap verhoogd.
Publicatie voltooid op bron `7e91aacfaea8491d88e1ccd5d8ba2684524c8621`.
Workflow [34270982612](https://github.com/Rakky88/DragonHaven/actions/runs/34270982612)
slaagt met schone analyse, 625 tests, productiepreflight en ondertekende AAB.
De productie-APK is als update getest; versie, vaste ondertekening en behoud
van spelgegevens en taalkeuze zijn gecontroleerd. GitHub-digest en grootte
zijn exact gelijk aan de lokale en geïnstalleerde APK; latest-download HTTP 200.
Ook na publicatie om 20:03:24 UTC: exact 57 migraties, nul lintfouten en
Auth/settings/app HTTP 200. Er is geen servermigratie uitgevoerd.
Volledig bewijs: [releaseverificatie](RELEASE_V0.05.21_VERIFICATION.md) en
[openbare release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.21).
De open servereconomiepunten en productie-instellingen blijven ongewijzigd.

## Uitgebracht: v0.05.20 (10070), 8 september 2026

Deze release bundelt de hieronder beschreven eventthema's, trainingmarkeringen,
drakeninformatie, Draconomicon-knoppen, testtrialbeloningen en vaste geslachten.
Appversie, updatevergelijking en Android-buildnummer zijn samen verhoogd.
Productie heeft exact migratie 57 gekregen, na vergelijking met het geslaagde
stagingbronbewijs 34254991384 en zes volledig teruggedraaide contractproeven
vóór en na toepassing. De productiepreflight om 18:23:52 UTC bevestigt 57
migraties, nul lintfouten en Auth/settings/app HTTP 200. Alle accounts blijven
legacy, economische mutaties en game-worker uit, nul schaduwkopieën; bestaande
productiepush blijft aan. Dit is geen activatie van de volledige servereconomie.
Publicatie voltooid op bron `aaafe6114eece36339ff26410fa4519ac1603e02`.
Workflow [34263298633](https://github.com/Rakky88/DragonHaven/actions/runs/34263298633)
slaagt met alle 621 tests, schone analyse, productiepreflight en ondertekende
AAB. De APK is op de emulator als update geïnstalleerd; de geïnstalleerde en
openbare checksum/grootte zijn exact gelijk aan het lokale releasebestand.
De vaste latest-download geeft HTTP 200. Ook na publicatie om 18:57:23 UTC:
schema 57, lint 0 en Auth/settings/app 200. Auditpunten voor volledige
servereconomie blijven open; deze release activeert die niet.
Zie [releasebewijs](RELEASE_V0.05.20_VERIFICATION.md) en
[openbare release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.20).

## Uitgebracht: v0.05.19 (10069), 7 september 2026

- Altar: sorteren op ontvangen/broedtijd, omkeren, tagfilters combineren en
  voorkeur delen met Inventory; details blijven verplicht vóór de selectie.
- Adventures: de i naast de relevante Expertise opent Might, Arcana en Spirit
  zonder de draak te selecteren of een avontuur te starten.
- Tutorial: 19 stappen, terugknop, juiste Conclave-tab, Altar/tags/Beacon,
  Expertise en niet-blijvende testeventbeloningen. Alle nieuwe teksten zijn
  vertaald in alle acht talen. Kleine schermen/grote tekst/landscape getest.
  Visuele controle vond daarnaast lege targets zonder online account; de tour
  gebruikt nu een bestaande tab als alternatief, de echte overlayafmetingen
  voor ankers, een eigen toegankelijkheidsroute en reset de tekstscroll per stap.
  Gerichte regressieproeven voor offline targets, teruggaan en scrollreset slagen.
- Productie heeft nu exact migraties 1–56. Alle zes contracten voor 50–56 zijn
  vóór toepassing in één rollbacktransactie geïsoleerd herhaald; getest
  stagingbronbewijs: 34153525465. Preflight: lint 0, Auth/settings/app 200.
  Alle accounts blijven legacy_client, economische mutaties uit, game-worker
  uit, nul schaduwkopieën. FCM-worker en Vault zijn ingericht; productiepush is
  aangezet na de geslaagde appreleasecontroles in workflow 34157071933.
  Dit activeert geen volledige servereconomie.
- Expliciete supportopdracht DH-4132F5C7: Love, Kisses, Hugs zijn in die volgorde
  via de normale join-RPC aangesloten. Lobby 2abfc0ab-e313-466a-9a64-11346dfcdc29
  is gestart met vier deelnemers; eindtijd 10 september 03:13:35 UTC.
  Tijdelijke draken hebben level 8, 10 per Expertise; geen bestaande speler-save
  of timer is aangepast. Eenmalige operationele cron controleert elk uur,
  verwijdert alleen de drie vastgelegde synthetische accounts nadat echte
  deelnemers hun beloning hebben bevestigd, en verwijdert daarna zichzelf.
  Eerste uitvoering geslaagd: alle drie bleven terecht bestaan tijdens de reis.

Publicatie voltooid: [v0.05.19](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.19),
bron `6982eba07394d7b6a7a08032f9f053ebbe680235`. Workflow 34157071933 slaagt
met schone analyse, 596 tests en een ondertekende AAB. De APK-versie en
handtekening zijn gecontroleerd; GitHub-digest en bestandsgrootte zijn identiek
aan het lokale artifact. De vaste latest-download geeft HTTP 200. Ook na
publicatie: schema 56, lint 0, Auth/settings/app 200. Volledig bewijs en links:
`RELEASE_V0.05.19_VERIFICATION.md`.

## Lopende opdracht: gratis Firebase en volledige servereconomie

Na de geslaagde release heeft Rick opdracht gegeven de servereconomie weer op
te pakken. Kandidaat 57 bouwt herstel bij twee beschadigde lokale verzoekkopieën:
een herhaalbare servergrens sluit onafgemaakte acties af, bewaart reeds bevestigde
uitkomsten en weigert ook oude verzoeken die pas later arriveren. De inventaris
verandert niet door herstel. Een apart dubbel herstelbestand houdt nieuwe acties
tegen totdat serverstand en weergave duurzaam zijn opgeslagen. Accountwissels en
onderbroken opruimen worden afgevangen. De databaseproef inclusief migratie is
op staging volledig teruggedraaid en slaagt. Alle 604 Fluttertests, 14 workerproeven
en de volledige analyse slagen. Workflow
[34254991384](https://github.com/Rakky88/DragonHaven/actions/runs/34254991384)
heeft daarna exact 57 toegepast, alle zes contracten herhaald en de echte
Auth/Edge/Dart/Postgres-proef bewezen. Tijdelijke accounts, kopieën, verzoeken en
herstelbewijzen zijn verwijderd; runtime uit, schema 57, lint 0, health 200.
Productie heeft 57 sinds de releasevoorbereiding van v0.05.20. De volgende appstap bundelt de losse transport-/opslagdelen
in één accountsessie met actuele serverweergave, offline lezen en duurzaam
hervatten. Acht nieuwe sessietests en 26 transport-/hersteltests slagen.
Workflow [34256256939](https://github.com/Rakky88/DragonHaven/actions/runs/34256256939)
bewijst ook de echte Flutter-client, SDK, opslagbestanden en server samen: een
verloren antwoord na een echte aankoop, herstart en beschadigde verzoekkopieën
geven precies één afschrijving. Testaccounts en gegevens opgeruimd, runtime uit,
schema 57, lint 0, health 200. Dit onderdeel is klaar; de sessie is nog niet aan
de echte spelschermen gekoppeld.

De aansluitend gevraagde productwijzigingen zijn op 8 september 2026 gebouwd
en gevalideerd; ze zijn gepubliceerd in release v0.05.20:
- eventthema door de app, vooral logo/achtergrond, plus een duidelijke eindtimer;
- Expertise-informatie ook in de trial-drakenkiezer;
- per draak Might/Arcana/Spirit kunnen markeren in My Dragons, dezelfde markering
  in informatievensters en een selectie “Highlighted for this path”;
- compacte Draconomicon-knop bovenin beide drakenkiezers;
- twee weken Halloween-testscores bewaren voor rangkalibratie en echte normale
  beloningen voor eventtrials in de testfase;
- permanent 50/50 male/female bepalen samen met de overige draakeigenschappen,
  met een klein icoon in My Dragons, behouden bij uitkomen/evolutie/overdracht.
Alle **621 Flutter-tests** slagen; de analyzer en referentiecontrole zijn schoon.
De app en gecompileerde servercode geven voor 109 identiteitsfixtures dezelfde
uitkomst. Beide kiezers zijn met grotere tekst getest en de schermbeelden zijn
visueel bekeken. Het rapport over de bestaande Halloween-testregistratie beslaat
8–22 september in Europe/Amsterdam en verandert geen live ranglijst.
Productiehealth is opnieuw 200/200/200 om 18:13:50 UTC. Er is geen migratie of
live economyactivatie uitgevoerd. Zie
[uitvoeringsbewijs](EVENT_THEME_AND_TRAINING_VERIFICATION.md).
De verdere volledige servereconomie blijft het volgende afzonderlijke traject.

Rick heeft de volledige servereconomie expliciet toegevoegd aan de scope en
zelf Firebase-project `dragonhaven-20ced` aangemaakt. Werkbranch:
`feature/free-monitoring-and-growth`. Hieronder staat het opeenvolgende bewijs
van de eerdere stappen; de actuele productie- en releasestatus staat bovenaan.

Migratie 54 en een expliciete leesweergave voor de app zijn op staging bewezen in
[34150477904](https://github.com/Rakky88/DragonHaven/actions/runs/34150477904).
Onbekende ei-genetica, seeds, toekomstige savevelden en verborgen inhoud in
handelsanimaties blijven privé. Lens, Oracle en Soul Mirror onthullen alleen
de verdiende informatie; leesacties veranderen geen beloningen of timers.
Acht projectietests en twaalf Edge-routetests slagen. Echte leesverzoeken blijven
werken bij uitgezette mutaties. De tijdelijke accounts/kopieën zijn verwijderd;
staging staat op 54, lint 0, health 200, runtime uit. Productie blijft op 49.
De ontvangende clientmodellen en het afzonderlijke opslagjournaal hebben veertien
tests voor accountwissels, vertraagde antwoorden, revisies, corruptie en
onderbroken schrijven. De volledige appkoppeling en live-overgang zijn nog niet
gereed; schaduwgegevens kunnen geen live inventaris vervangen.

De client bewaart spelverzoeken nu dubbel met checksum en hervat hetzelfde
verzoeknummer. Elf tests bewijzen herstel na een verloren serverantwoord,
lokale opslagfouten, dubbele tikken en accountwissels; afhandelen gebeurt pas na
het bewaren en verwerken van de nieuwste serverinventaris. Lokale migratie 55
maakt oude uitkomsten opvraagbaar tijdens een mutatiepauze zonder nieuwe acties
toe te laten. Stagingrun
[34151895090](https://github.com/Rakky88/DragonHaven/actions/runs/34151895090)
bewijst dit met echte requests; schema 55, lint 0, health 200, testaccounts
opgeruimd en runtime uit. Zeven lokale SDK-tests bewijzen daarnaast de client-
transportkoppeling met de bestaande login, accountwissels, begrensde antwoorden
en het sluiten van vastgelopen verbindingen. Productie blijft op 49.
Herstel wanneer beide verzoekkopieën
beschadigd zijn en de daadwerkelijke appschermen blijven open werk.

Lokale vervolgstap 56 ordent leesweergaven ook over spelregelupdates heen.
De spelrevisie en spelregelrevisie worden afzonderlijk bewaakt en opgeslagen;
een nieuwe weergave mag dezelfde inventaris vervangen, een laat oud antwoord
mag dat niet terugdraaien. Zestien snapshotproeven slagen, inclusief een
onderbroken update waarbij alleen de spelregels wijzigen. Run
[34153525465](https://github.com/Rakky88/DragonHaven/actions/runs/34153525465)
heeft 56 toegepast, contracten 52–56 en de volledige echte Auth/Edge/Dart/Postgres-
proef doorlopen. Staging: schema 56, lint 0, health 200, runtime uit, tijdelijke
accounts en schaduwverzoeken verwijderd. Dit begrensde serveronderdeel is klaar.
De eierkiezer, Expertise-informatie, tutorial en nieuwe release zijn afgerond;
Rick heeft het vervolg van de volledige servereconomie inmiddels hervat.

Productie- en staging-Firebase zijn ingericht zonder billingaccount. Staging
gebruikt `dragonhaven-prod-rakky88` met weergavenaam DragonHaven Staging.
De Android-koppeling, privacyarme Crashlytics/Performance-reporter, account- en
apparaatgebonden pushregistratie, polling-levenscyclus en FCM-worker zijn gebouwd.
De sender heeft alleen `cloudmessaging.messages.create`.

Migraties 50-51 zijn uitsluitend op staging toegepast na rollbackrepetitie:
[34136004296](https://github.com/Rakky88/DragonHaven/actions/runs/34136004296),
[34136928567](https://github.com/Rakky88/DragonHaven/actions/runs/34136928567).
Pariteit/lint/health slagen; push staat standaard uit. Echte aflevering via cron,
Vault en Edge worker is bewezen in
[34137456672](https://github.com/Rakky88/DragonHaven/actions/runs/34137456672):
generiek bericht zichtbaar op het testtoestel, inbox bleef ongelezen, fixture
verwijderd en push weer uit. De echte FATAL- en NON_FATAL-testmeldingen zijn
ook teruggevonden in de Firebase Crashlytics API.

Android bouwt zonder en met Firebase-configuratie. De volledige Flutter-suite
slaagt met 552 tests; de aanvullende native pariteitsfixture slaagt ook.
Analyzer is schoon voor lib, tests, integratietests en tools. De vaste
schemaverwachting is bijgewerkt naar de lokale kandidaat 53. Zes Deno-pushworkerproeven slagen.
Zie `FIREBASE_MONITORING_SETUP.md` voor
bewijs en resterende alertinstellingen. Rick heeft de zichtbare stagingtrace
`dh_staging_probe` bevestigd; de echte release-R8-mappingupload slaagt ook.
De normale openbare v0.05.18-app is teruggezet op het testtoestel, met behoud
van opslag. Tijdelijke probe-tokenbestanden en het GitHub-probetokensecret zijn
verwijderd; Crashlytics-debuglogging is teruggezet naar INFO. Ook een normale
releasebuild met staging-Firebase is lokaal geslaagd.

De gedeelde spelregels zijn losgemaakt van Flutter-platformdiensten en
compileren naar een interne servermodule van minder dan 1 MB. Een synthetische
VM/Deno-vergelijking van chests, aankopen, inventaris, ei-eigenschappen en IDs
slaagt. Twaalf gerichte tests dekken onder meer herstelbare vaste serverrandomness,
saldo-/voorraadgrenzen, tags, Sinister-confirmatie, quillverbruik en incubatie.
Migratie 52 bevat nu een lokale kandidaat voor de transactie rond een
afzonderlijke volledige savekopie. Zij kan alleen schaduwkopieën bijwerken;
live saldo, inventaris, Altar en accountautoriteit blijven onaangeraakt.
De rollbackproef slaagt in
[34143594035](https://github.com/Rakky88/DragonHaven/actions/runs/34143594035):
volledige kopie, leases/replay, eigenaar-/saldocontroles en accountverwijdering.
Alle wijzigingen draaiden terug; staging blijft 51. Een extra semantische
controle weigert saves waarvoor laden bezittingen verwijdert, vaste ei- of
relic-eigenschappen herloot of voortgang wijzigt; die vragen eerst reconciliatie.
Volledige reconciliatie/projectie, trialvalidatie
en daadwerkelijke clientomschakeling zijn nog niet gebouwd of vrijgegeven.

De bijbehorende Edge worker is gebouwd en lokaal getypecheckt. Negen proeven
dekken aanmelding, geweigerde vervalste invoer, afgeschermde servergegevens,
replay na verloren commitantwoord en begrensde requests. De echte stagingproef
wordt via een aparte workflow uitgevoerd op tijdelijke synthetische accounts;
geen live speler kan via deze schaduwroute saldo of inventaris wijzigen.
Run `34146256475` heeft daarna precies migratie 52 toegepast en de worker
uitgerold. Contracten vóór/na, pariteit 52, lint en health slagen. De HTTP-proef
stopte vóór accountcreatie op een onleesbaar managementantwoord; de volledige
workerproef wordt pas geaccepteerd na een geslaagde hercontrole.
De interne Altar-conversie is nu gebouwd met zes gedragstests: actuele servertags,
behouden ontdekkingen, geen tweede beloning voor eerdere returns en blokkering
van tegenstrijdige of verouderde saves. De transactie voor het vastleggen van
deze voorbereiding en de daadwerkelijke accountomschakeling blijven open.

De volledige echte workerproef is nu geslaagd in
[34147658644](https://github.com/Rakky88/DragonHaven/actions/runs/34147658644):
Auth, Edge, gedeelde Dart-regels en PostgreSQL, inclusief gelijktijdig openen,
idempotente aankopen, tags, Sinister-confirmatie/beloning en quillverbruik.
Live save en wallet bleven exact gelijk. Twee synthetische accounts plus alle
schaduwgegevens zijn verwijderd; runtime weer uit, pariteit 52, lint nul en
health 200. De eerdere harnasfouten zijn opgelost (HTTP 201, keuze van een echt
Sinister-ei en een eindcontrole zonder private functies onder de leesrol).

Kandidaat 53 bewaart opeenvolgende importgeneraties onveranderlijk en legt de
Altar-voorbereiding alleen vast als bron, Altar en revisie nog overeenkomen.
De rollbackrepetitie wordt afzonderlijk uitgevoerd; 53 is nog niet toegepast.
Deze repetitie is geslaagd in
[34148415163](https://github.com/Rakky88/DragonHaven/actions/runs/34148415163).
De gecombineerde stagingpoort past daarna 53 toe en test de echte interne
voorbereiding plus dezelfde spelacties. Die gecombineerde proef staat nog open.
De gecombineerde proef is geslaagd in
[34148722971](https://github.com/Rakky88/DragonHaven/actions/runs/34148722971):
53 toegepast, beide contracten herhaald, echte Altar-voorbereiding/replay en alle
spelacties groen. Alle synthetische gegevens zijn verwijderd en runtime staat
weer uit. Eindcontrole: staging 53, lint nul, health 200; productie blijft 49.

`GROWTH_AND_COST_PLAN.md` bevat de 100/1.000/10.000-accountscenario's, bestaande
loadbewijzen, quota, opslag/egress-aannames en meetbare overstappen. De lokale
rekentool en SQL-capaciteitsrapportage bevatten uitsluitend technische gegevens.
De volledige economie is in uitvoering: conversie, duurzame snapshots,
overige aankopen, ei-/draaklevensloop, claimvalidatie en herstel-/stagingproeven
blijven open. Productie blijft schema 49, legacy en mutations=false.

## Gepubliceerde release v0.05.18 / 10068 (7 september)

De nieuwe release bundelt de onderstaande auditbouw en UI-correcties. App,
updater en Android gaan precies één stap omhoog. Migratie 49 is identiek aan
de geslaagde stagingrun `34127201082`; de productiepoort eist dezelfde volledige
migratiegeschiedenis en SQL-contractbron, oefent de wijziging met rollback en
controleert vóór en na dat de economie uitstaat en alle accounts legacy blijven.
Productiepariteit, analyse/tests, visuele APK-controle en de
ondertekenings-/downloadcontroles zijn afgerond. De 1000-accountcapaciteit blijft afgekeurd
en wordt niet stilzwijgend geaccepteerd door deze release.

Productierun [34129277707](https://github.com/Rakky88/DragonHaven/actions/runs/34129277707)
is inmiddels geslaagd: 48 naar 49, identieke stagingbron, rollbackrepetitie en
herhaalde snapshotcontractproef. Nacontroles in CI en lokaal: 49 migraties,
nul lintfouten, Auth/settings/app-health 200. Voor en na: mutations uit,
nul niet-legacy accounts. Alle 518 lokale tests slagen en analyzer is schoon.
De ondertekende APK is gebouwd en als update over v0.05.17 geïnstalleerd op
`emulator-5554`: pakket `nl.dragonhaven.app`, versionName 0.05.18 en code 10068,
bestaande voortgang behouden en het vaste certificaat gecontroleerd. Trials,
shop en Inventory zijn visueel beoordeeld op circa 411 dp en 320 dp, inclusief
uitgeschakelde animaties. De taalkeuze staat alfabetisch, Nederlands blijft na
herstart geselecteerd en About toont v0.05.18. De Conclave-leesstatus is bewezen
via de volledige-shellregressie; op de emulator is alleen de uitgelogde
Friends/Conclave-layout bekeken. Er zijn geen echte chatberichten verzonden.
Screenshots en logs staan lokaal onder `release/v0.05.18-*`.
APK: 505.821.796 bytes; SHA-256
`e956b358d51e9304cd0f78647a4ccf9e447f0c85fc69152cfad06f00b0add89a`.
Alle 48 openbare release-notes-bestanden zijn gecontroleerd op afgeschermde
codewaarden en aankondigingen. [Release v0.05.18](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.18)
is gepubliceerd als Latest op commit `1d57cbe4506847293be690cab5f47a3dad5b4089`.
De versiegebonden en permanente APK-download antwoorden met 200 en de juiste
grootte; GitHub bevestigt exact dezelfde SHA-256. Productiehealth na publicatie
is groen (Auth/settings/app 200). De onafhankelijke
[AAB-run 34130064067](https://github.com/Rakky88/DragonHaven/actions/runs/34130064067)
is volledig geslaagd: productiepariteit 49, analyzer, tests, bundlebuild,
versie 0.05.18 / 10068 en het vaste certificaat. AAB SHA-256:
`203feef6bfbc978969a092c64cd58ce559558ec1be1bd8f004a3740f51fcb521`.
Het ondertekende bundle en server-/releasebewijs staan in het CI-artifact
`DragonHaven-Play-Store`. Dit is geen publicatie in Google Play.

## Historische auditbouw tussen v0.05.17 en v0.05.18 (7 september)

Op `feature/audit-capacity-and-import` is de Auth-opbouw gescheiden van de
gemeten spelbelasting. Run [34119032803](https://github.com/Rakky88/DragonHaven/actions/runs/34119032803)
bewees 100 volledig ingelogde en tegelijk actieve accounts, 180 seconden
steady state na 60 seconden opbouw, 1.544 lees-RPC's zonder fouten en p95
239-298 ms. Alle 100 accounts zijn verwijderd; schema 47, lint en health zijn
voor en na groen. CPU/geheugen/hostnetwerk zijn apart gemeten; piekverbindingen
en gefactureerde egress ontbreken nog. Dit betreft lezen met verse synthetische
accounts, geen bewijs voor grote bestaande inventarissen of schrijfpaden.

De eerste 1000-poging `34120079328` stopte voor de meting: de Linux-limiet voor
een environment-string blokkeerde het starten van de runner. Alle 1000
accounts zijn opgeruimd; de server bleef gezond. Commit `c2b2d2f` vervangt die
overdracht door een private, begrensde stdin-pipe, met een offline procesproef
boven 128 KiB. Vervolgmeting `34121385770` bereikte 1000 tegelijk actieve
accounts, maar is **afgekeurd**: 3729 van 7769 reads eindigden in een
netwerk-time-out (47,998%). De runner schreef zijn rapport en bleef daarna
leven; gecontroleerde annulering activeerde herstelcleanup van alle 1000
accounts. Onafhankelijke nacheck `34127372780` bevestigt nul achterblijvers.
De time-outfase wordt voortaan apart gemeten, vastgelopen requests worden
afgebroken en de runnerafsluiting is begrensd. De oorzaak van de 1000-account-
time-outs is nog niet geïsoleerd; capaciteit voor 1000 is niet geaccepteerd.
Het volledige bewijs en de beperkingen staan in `STAGING_LOAD_TEST.md`.

De gecontroleerde legacy-import-/herstelproef is **geslaagd** in run
[34120524533](https://github.com/Rakky88/DragonHaven/actions/runs/34120524533).
De volledige wallet- en inventarisrijen plus SHA-256 zijn exact hersteld.
Gedeeltelijk falende import/herstel, gewijzigde voortgang, verlopen backups,
verkeerde eigenaars en serveraccounts zijn getest. Audit en eenmalige importlock
blijven behouden. De aanvraag duurde 1.250 ms; de synthetische restore bleef
onder 10 seconden. Alles draaide terug; schema 47, nul lintfouten en health 200.
Dit is een tijdelijke SQL-repetitie; een operationele restore van echte accounts
en de volledige aggregate-naar-instanceconversie blijven afzonderlijk open.

Op staging bewezen migratie **49** voegt een gepagineerde, alleen-lezen inventarisroute
toe voor toekomstige serveraccounts. De client verzamelt uitsluitend complete
pagina's van dezelfde eigenaar/revisie en bewaart absolute saldi en vaste
Chronoshard-waarden. Negen gedragstests zijn groen. Stagingrun `34127201082`
bewees de rollbackrepetitie, exacte toepassing van 49, herhaalde inventaris-/
foundation-/vanity-/chest-/shopcontracten, nul lintfouten en health 200.
Productie staat op 48; de openbare app blijft v0.05.17.
Het toepassen op lokale opslag/UI, volledige instanceconversie en de
ei-/draaklevensloop zijn hiermee nog niet afgerond.

Op jouw aanvullende verzoek opent afzonderlijke migratie **48** alleen de
Halloween-preview voor alle ingelogde keepers met bevestigde e-mail. De overige
vier previews blijven afgeschermd. Actieve previews behouden hun oorspronkelijke
vervalmoment; de extra clienttests bewijzen nul blijvende beloningen voor test-
Trials, test-adventures en gesimuleerde duo-adventures. Stagingrun `34122815644`
en productierun `34127198552` zijn groen: identieke migratie 48, geteste publieke
toegang, behoud van actieve vervaltijd en nul blijvende previewbeloningen.
Productiepreflight bevestigt 48 migraties, nul lintfouten en health 200; de
economie blijft uitgeschakeld en alle accounts behouden legacy-authority.
De Halloween-code werkt ook voor bestaande v0.05.17-clients. Migratie 49 is
uitsluitend op staging toegepast.

Tussentijds verzoek uitgevoerd: Inventory toont nu lokaal **Eggs, Chests,
Altar, Relics, Furniture**; bestaande Altar-widgettests en de levende referentie
zijn bijgewerkt. De productierelease wordt hierdoor niet stil vervangen.

Een aanvullende Conclave-regressie is via de volledige hoofdnavigatie
gereproduceerd: `FriendsScreen.active` verwees naar Tower-index 2 terwijl
Friends index 0 heeft. De correctie laat de badge bij zichtbare nieuwste
berichten verdwijnen en houdt berichten ongelezen terwijl Tower zichtbaar is.
De proef faalde vooraf met 40 ongelezen berichten en slaagt na de correctie,
inclusief omhoog/omlaag scrollen en terugkeren via de navigatie. De volledige
lokale suite is **516/516 groen**, analyzer meldt nul problemen en de levende
referenties zijn gesynchroniseerd. De appfix is nog niet publiek uitgebracht.

Een afzonderlijke SQL-hotfixrepetitie is geslaagd in stagingrun `34127201082`.
Deze gebruikt sessielokale kopieën van de echte timestampfout uit migratie 37
en de correctie uit 38. De proef controleert foutreproductie, atomair falen,
timestampvenster, limiet en reset, plus ongewijzigde geïnstalleerde functies,
rechten en activatie. De aanvraag duurde 795 ms en alles draaide terug. Dit is
nog geen uitgevoerde operationele detectie-/communicatie-/compensatieoefening.

Twee volgende compactheidsverzoeken zijn lokaal uitgevoerd: de zevendaagse
constellation staat binnen dezelfde paarse Trials-header, en de Furniture-shop
heeft geen geel verzamelblok of vast aantal in de zoektekst meer. De Trials-
header is visueel gecontroleerd op 320 logische pixels breed
(`release/polish-trials.png`). De 82 relevante widget-/lokalisatie-/referentietests
slagen; analyzer meldt nul problemen. Gameplay, prijzen en beloningen wijzigen
hierdoor niet. Ook deze UI-wijzigingen wachten op een volgende apprelease.

Afsluitende validatie: de volledige suite bevat 518 tests. Daarvan slaagden
517 direct; één vaste tekstcontrole moest na de actualisering van het
economiecontract worden hersteld. De daaropvolgende 68 contract-/audit-/loadtests
zijn allemaal groen, net als analyzer en referentieguard. Linux-planrun
`34128315798` slaagt met de aangepaste CLI en de offline transport-/cleanup-/
metricscontroles, zonder accounts aan te maken of load uit te voeren. Dit
valideert de hulpmiddelen; de afgekeurde 1000-accountmeting blijft afzonderlijk
open. Geen nieuwe APK of appversie is uitgebracht in deze auditbouwtranche.

## Gepubliceerde release v0.05.17 / 10067 (7 september)

Release **v0.05.17** is gepubliceerd als Latest met appcommit en tag
`a706a120a8f0b8cc3fb49d85096c4efeac5f5384`. About, updater, Android versionName
0.05.17 en versionCode 10067 zijn gelijkgetrokken met precies een versiestap.
De release bevat de nieuwe Inventory > Altar-tab, verbeterde Altar-compositie
en animatie, ei-informatie voor plaatsing, compacte craftkeuzes met Quill
vooraan, een tutorial zonder odds/teller, compacte Trials-informatie, de
volledige Might-sprite en zes aparte, subtiel verschillende Arcana-pompoenen.

**501/501 tests groen**, ook zonder extra lettertype-omgevingsvariabelen;
analyzer schoon en levende referenties gesynchroniseerd. De releasecontrole
vond en herstelde twee compacte layouts: Altar-tag/details-knoppen mogen
omlopen en de fase-iconen in de seasonal HUD passen binnen de beschikbare
breedte. De Trial-titel blijft maximaal twee regels. Updaterfixtures en het
staging-first-workflowcontract volgen de nieuwe release. Alle 47 openbare
release-notesbestanden zijn vrij van private codes en aankondigingen daarvan.

**Bij deze release stonden productie en staging op 47/47 migraties.** Productierun `34116589237`
vergeleek migraties en contracten exact met de geslaagde stagingrun `34111166461`
op commit `c57381b546e920822103b12d8466623ee89733a3`. Begintoestand 44, volledige
baseline, de exacte pending set 45-47, health, lint en dry-run zijn gecontroleerd.
Alle drie migraties met zowel chest-, item-shop- als bestaand Altar-contract
zijn eerst gerepeteerd met rollback. Na toepassing zijn alle contracten opnieuw
teruggerold bewezen. Pariteit, nul lintfouten en Auth-/apphealth 200 zijn groen.
Voor en na de uitrol: `mutations_enabled=false` en nul spelers buiten
legacycompatibiliteit. De onafhankelijke lokale serverpreflight was groen om
11:27:52 UTC. De bredere economycutover blijft uitgeschakeld.

De ondertekende APK is succesvol als update op emulator-5554 geinstalleerd;
de bestaande draak, voortgang en opgeslagen Engelse taalkeuze bleven behouden.
Altar, crafting, tutorial, compacte Trials en About zijn op het apparaat
gecontroleerd, ook op 320x640 met animaties uit. Alle acht talen staan op
zichtbare taalnaam in alfabetische volgorde. Emulatorinstellingen zijn hersteld;
geen Flutter- of Android-runtimefouten. Volledige retour-/Sinister-/Beacon-acties
en Arcana/Might zijn aanvullend in widgettests en de eerdere visuele opnames
gecontroleerd; bij de apparaatcontrole zijn geen echte eieren of materialen
verbruikt. De zes pompoenen, Might-sprite en beide Altar-sceneafbeeldingen in
de APK komen byte voor byte overeen met de releasebron.

APK: `DragonHaven.apk`, **505821796 bytes (482.4 MiB)**.
SHA-256: `5377b9e7017bcfd8bedc5bdd2c61bfeb264f20859f0c77a654aeaeae9ede98ee`.
Certificaat: `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
Publisher-dry-run en upload geslaagd. Om 11:42:31 UTC zijn Latest, remote
digest, bestandsgrootte en vaste downloadlink (HTTP 200) onafhankelijk bevestigd.
De controle na publicatie om **11:42:32 UTC** geeft opnieuw HTTP 200 voor beide
Auth-endpoints en applicatiehealth. Tagworkflow `34117568948` is volledig
geslaagd: productiepreflight, analyzer, volledige tests en het ondertekende
Play-bundle. AAB-SHA-256:
`916a112d401fe70100e467f95a7d0a9276872c7c3093d9bbb40c2001b308f4b6`;
versionCode 10067 en het vaste signingcertificaat zijn bevestigd. Deze workflow publiceert geen
GitHub-releaseasset, zodat er maar een APK-publisher actief is.

- Release: https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.17
- APK: https://github.com/Rakky88/DragonHaven/releases/download/v0.05.17/DragonHaven.apk
- Vaste link: https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk

De audit is hiermee bijgewerkt, niet volledig afgerond: fase 4B blijft deels
open, fase 4C/4D en supportcontactgegevens blijven open. De eerdere Auth-
loadbevinding blijft staan; deze release claimt geen bewezen capaciteit voor
100 of 1000 gelijktijdige spelers en versoepelt geen Auth-beveiligingslimieten.

## Auditbouw voorafgaand aan v0.05.17 (7 september)

Nieuwe kandidaat op `feature/audit-server-economy`: migratie 45 voor het openen
van alle kistinstanties op de server, migratie 46 voor het weigeren van oude
inventarisuploads bij toekomstige serveraccounts. Beloningen, pity, unieke
collecties, Special-eieren, vaste Chronoshard-percentages en Twinstar-historie
worden atomair met de kist en de herhaalbare ontvangstbevestiging vastgelegd.
De appgrens ondersteunt getypeerde ontvangsten en een per-account op schijf
bewaarde aanvraag die een timeout of herstart overleeft. Geen activatie in de UI.

De gerichte client-/catalogus-/fundering-/referentietests zijn groen (33).
Stagingrepetitie `34110497546` en toepassing `34110676557` zijn groen:
46 migraties, nul lintfouten, Auth-/apphealth 200 en zowel de funderings-,
aankoop- als chestcontracten teruggedraaid bewezen. Productie blijft op 44.
De volledige suite vond alleen een verouderde verwachting van migratie 44 in
de loadprofieltest; die volgt nu de nieuwe kandidaat. Analyzer was schoon.
Migratie 47 voegt nu gewone meubelaankopen en vier winkelrelics toe met prijzen
uit de bestaande catalogus, vaste tradeability en herhaalbare ontvangsten.
Stagingvalidatie van 47 is groen in run `34111166461`: exacte 47-migratiepariteit,
nul lintfouten, Auth-/apphealth 200 en alle aankoop-/chest-/winkelcontracten
binnen rollback bewezen. Productie blijft op 44.
Fase 4B is hiermee uitgebreid, niet afgerond: andere winkels, volledige
conversie van bestaande stacks, snapshotreconciliatie en activering ontbreken.
Fase 4C (ei-/draaklevensloop) en 4D (beloningsclaims) blijven open. Voor de
support-/privacywebsite zijn de definitieve contactgegevens nog nodig.

Tussentijdse UI-verzoeken zijn in deze kandidaat meegenomen: Inventory > Altar,
compacte receptkaarten met Quill vooraan, ei-informatie voor selectie, een
tutorial zonder odds/teller, een vaste altaarcompositie met vloeiend licht en
deeltjes, compactere Trial-informatie en zes aparte Arcana-pompoensprites.
De Might-sprite gebruikt de volledige oorspronkelijke uitsnede met marge.
Visuele controles op 320 x 640 omvatten Arcana, Might, de compacte Trialpagina,
Altar-selectie, ei-informatie, crafting, tutorial, zes animatiemomenten en het
resultaat. De volledige suite is groen: **501/501 tests**. Analyzer meldt
**No issues found**; de levende referentiedocumentatie is gecontroleerd.

Het staging-loadprofiel kan nu zelf tijdelijk bevestigde synthetische accounts
maken zonder e-mail en ruimt alleen eigen runaccounts weer op. De 1000-userpoort
eist 100 geslaagde logins en bootstraps op hetzelfde schema. Beide kanten van de
run controleren pariteit, lint en health. De eerste poging `34114939684`
stopte zonder accounts of load door een transportfout in de setupwrapper; die is
hersteld en met een offline contract voor transport en opruimisolatie afgedekt.
Run `34115250094` heeft 100 accounts gemaakt en alle 100 weer verwijderd.
De meting faalde terecht: 59/100 logins en bootstraps slaagden, 41 logins kregen
HTTP 429 (4,762% fouten over alle 861 aanvragen; 41% van de logins).
Alle 702 lees-RPC's slaagden, met p95 309-322 ms; snapshot p95/p99 319/336 ms.
Stagingpariteit 47, nul lintfouten en Auth-/apphealth 200 zijn ook na de run bewezen.
De 1000-userpoort is gesloten gebleven. Dit bewijst nog geen capaciteit voor 100
of 1000 actieve spelers: het inloggen vanuit dezelfde CI-runner raakt de Auth-
begrenzing. Een volgende meting moet normale sessieopbouw scheiden van een
loginpiek, zonder beveiligingslimieten te versoepelen; provider-CPU/verbindingen/
egress blijven afzonderlijk nodig.

Release **v0.05.16 / versionCode 10066** is op 7 september 2026 gepubliceerd als
Latest. APK-upload en definitieve downloadcontrole zijn geslaagd. De app en updater gebruiken
beide 0.05.16. De release bevat Egg Altar, beschermtags, vijf craftrecepten, zes
animatiefasen en de cosmetische Conclave Weave Beacon. Sinister geeft altijd 25
Fragments, 3-5 Essence met gelijke kansen en 10% kans op een Weaveheart; de extra
bevestiging vermeldt alleen de definitieve teruggave. Witchlight heeft wisselende
paden van gelijke lengte, zwart pad, vingertrail, rode foutflits en game over bij
drie fouten of verstreken tijd. Het eerste pompoenvoorbeeld blijft een seconde
langer staan. De Conclave-badge heeft eigen ruimte en gelezen chat wordt na het
voltooien van de scroll verwerkt. Het paarse Friends-introblok is verwijderd.

Appcommit en tag v0.05.16: `0d1d44d638423ce5988ab140db026ca97e81d55d`.
Analyzer schoon, **486/486 tests groen**, levende referenties gesynchroniseerd
en PowerShell-stappen van de productieworkflow correct geparseerd. De vaste
releasehandtekening is gecontroleerd; de APK is als update op de emulator
geinstalleerd, met versionName 0.05.16 en versionCode 10066. About toont dezelfde
versie. Friends-tabs, Altar, opbrengstuitleg, crafting en Quill zijn visueel
gecontroleerd, ook op 320x640 met animaties uit. Taalvolgorde en bestaande
Engelse selectie bleven behouden. De emulatorinstellingen zijn hersteld.
De complete retour-/Sinister-/Beacon-acties zijn via de widgettests en het
SQL-contract gecontroleerd; er zijn bij de visuele controle geen echte eieren
of materialen verbruikt. Alle 15 Altar-PNG's zijn aanwezig in de APK.

**Productie en staging staan op 44/44 migraties.** Productierun `34107061124`
controleerde de geslaagde stagingrun `34106264418` en vergeleek alle migraties en
het Altar-contract exact met stagingcommit `174fd3a`. Vervolgens: exact de
begintoestand 41, health/lint, dry-run, alle drie migraties plus contract in een
teruggerolde repetitie, toepassing van alleen 42-44 en opnieuw contract, parity,
lint en Auth-/apphealth. Alles is groen. Het contract gebruikt tijdelijke
accounts en draait alle testmutaties terug. De onafhankelijke lokale
`release_server_preflight.ps1` bevestigde 44 migraties, nul lintfouten en HTTP 200
voor Auth health, Auth settings en applicatiehealth om 09:39:08 UTC.

De bredere economycutover blijft uit. Bestaande clientinventarisregistratie blijft
een vertrouwensgrens; het aparte Altar-register beveiligt verdere transacties,
maar maakt de complete legacy loot-economie niet server-authoritatief.

APK: `DragonHaven.apk`, 502710087 bytes (479.4 MiB).
SHA-256: `300b869ca9c24b9e6ffc64f7d82995b7cf0b0287ea9bde93dd2e6ca6671524bf`.
Certificaat: `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
De publisher-dry-run is groen. Tagworkflow `34107336773` is volledig groen:
productiepreflight, analyzer, tests, ondertekend Play-bundle, certificaatcontrole
en artifactupload. AAB-SHA256:
`c980cdf953bcc31ff02ced95dbae7e396af45510a67d856e600b34cd98c0ea07`.

Publicatiecontrole: release-API en Latest wijzen naar v0.05.16. Het publieke
bestand DragonHaven.apk heeft exact dezelfde 502710087 bytes en SHA-256 als
de lokaal gecontroleerde APK. De release notes komen inclusief Unicode overeen
met het bronbestand. De vaste downloadlink geeft HTTP 200. De onafhankelijke
controle na publicatie gaf om 09:52:09 UTC opnieuw HTTP 200 voor Auth health,
Auth settings en applicatiehealth. Bewijzen staan lokaal in
`release/v0.05.16-remote-verification.json`,
`release/v0.05.16-health-after-publication.json` en de release-/productierunlogs.

- Release: https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.16
- Versie-APK: https://github.com/Rakky88/DragonHaven/releases/download/v0.05.16/DragonHaven.apk
- Vaste download: https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk

Eerdere previewbewijzen: stagingrun `34102634420` testte de oorspronkelijke
migraties 42/43, en Android-previewrun `34103519418` op commit `d5cf9ed` leverde
artifact `10011704404` met debugcertificaat
`7354973a274555fa6b0fff0faee11f16dca44cd4f579d924f7d85a44d1119804`.
Preview-APK-SHA256:
`99b16a3dacdf3ae5dc3aef117eaee13bdf8a6e69a8de891e707db68aa41d979b`.
Die preview is ouder dan de laatste Friends/Sinister-aanpassingen en is vervangen
door de productie-APK van v0.05.16. De eerdere volledige suite had 485 tests;
de Sinister-vervolgwijziging doorliep 150 gerichte tests en stagingrun `34106264418`.
Draft-PR #2 documenteerde die featurevoorbereiding ten opzichte van v0.05.15.
Deze PR is na de geslaagde publicatie gesloten en verwijst naar v0.05.16.

Release **v0.05.15 / versionCode 10065** bevat de aangevraagde
Friends/Conclave-tabs, een lokale ongelezen-teller per account en Conclave voor
berichten jonger dan 24 uur (eigen berichten uitgesloten), pompoengezichten voor
Witchlight Arcana, continu padtraceren voor Spirit, een uitslag zonder extra
sterren en actieve avonturen op oplopende eindtijd. Nog niet gestarte groepen
staan onderaan. De chat wordt alleen gelezen gemarkeerd wanneer de chat zichtbaar
is en de speler bij de nieuwste berichten is. De teller synchroniseert niet
naar andere apparaten; hij ververst tijdens het actieve appproces elke 30 seconden.

Releasecontrole: de eerste volledige suite vond ontbrekende vertalingen van de
nieuwe uitleg en een updatefixture die niet meer nieuwer was dan de app. De
vertalingen zijn voor alle zes extra talen aangevuld en de fixture biedt nu
v0.05.16 aan een v0.05.15-app aan. De gerichte sociale suite (51 tests) en de
Trial-/documentatiecontroles zijn groen. Volledige hervalidatie is groen: 467/467 tests. De ondertekende APK heeft
versie 0.05.15, buildnummer 10065 en hetzelfde vaste certificaat als v0.05.14.
Friends/Conclave en About zijn op de emulator gecontroleerd; compacte
Witchlight- en uitslaglayouts en reduced motion vallen onder widgetcontroles.
Publicatie en downloadverificatie zijn afgerond; zie de bewijsregel van v0.05.15 onderaan.

De lokale productiepreflight op 7 september 2026 bevestigde 41/41 migraties,
nul database-lintfouten, Auth health/settings HTTP 200 en applicatiehealth HTTP
200. Deze release wijzigt geen migraties, serverfuncties, economyactivatie of
beloningstabellen.

Actuele productieserver: **44 toegepaste migraties; gezond, met nul
database-lintfouten en groene Auth-/applicatiehealth**

Vorige serveruitrol: **staging en productie stonden beide op 41/41. Stagingrun
`34072959455` bewees de forward-only lintfix, parity, nul lintfouten,
RLS/revokes, dormante economyrollback, seasonal preview/Trial/ranking-E2E en
Auth/apphealth. Productierun `34073058141` bracht daarna uitsluitend migraties
37–41 over en herhaalde dry-run, parity, lint en health groen. De onafhankelijke
lokale productiepreflight bevestigde opnieuw 41 migraties, nul lintfouten en HTTP
200 voor Auth en applicatiehealth. Migraties 37–39 houden alle keepers in
`legacy_client`, de globale mutatieschakelaar uit en de appfeature uit;
migraties 40–41 voegen de online eventcontracten toe zonder de bestaande
economie te activeren.**

Eerdere uitgebrachte tranche: **v0.05.14 brengt de vijf volledige seasonal
events uit met versionCode 10064. Analyzer, alle 458 tests, vaste signing,
productiepreflight, Play-ready AAB, remote APK-assetcontrole en post-release
health zijn groen. De APK staat exact op commit
`768a6ac48f681d3d9bea2ea63a6048bde4c453d2`; productie en staging zijn gezond
op migratie 41/41.**

Actuele audittranche naast v0.05.14: **auditfase 4A en de eerste dormante 4B-
aankoop staan op staging en productie. De authoritymodus blijft voor alle
Keepers `legacy_client`, de globale mutatieschakelaar en appfeature blijven uit,
en de stagingrollback bewees dat de nieuwe kooproute geen waarde achterlaat.
Volgende Codexstap is server-owned chestopening met randomness, pity en
relicdrops; activering voor spelers blijft een afzonderlijk gezamenlijk besluit.**

Eerdere seasonal release v0.05.14: **de vijf volledig goedgekeurde
eventcontracten voor Halloween, Kerst, Nieuwjaar, Valentijn en Pride zijn
uitgebracht. Dit omvat vijf kalender-/previewvensters, vijf Special Adventures,
vijf event-Trials met eigen hoogwaardige media, vijf nieuwe Special families,
eventspecifieke chests/eggs/audio, tijdelijke publiek-domeinmuziek, wereldwijde
ranglijsten met vijfdaagse uitslag en permanente Chronicle, idempotente
podiumprijzen, een wereldwijde Pride-meter en de tweepersoons Valentijnsflow.
Saveschema 53 bewaart nieuwe lokale idempotentievelden; migraties 40–41 bevatten
de server-RPC's/RLS en forward-only lintfix. De oorspronkelijke grote bronplaten staan buiten Flutter's
assetbundle. De volledige verscheepte seasonal toevoeging is circa 57,0 MiB:
28,4 MiB event-UI, 26,5 MiB draken en 2,0 MiB audio, zonder lagere
runtime-WebP-kwaliteit. Appversie `0.05.14+10064`; analyzer, alle 458 tests,
PowerShell-parse, levende-documentatie-, transparantie-/safe-area- en
signingpoorten zijn groen. De echte release-APK is als update op de emulator
geïnstalleerd en toont Android-versionName `0.05.14` en versionCode `10064`.
Migraties 39–41 doorliepen de exact begrensde stagingpoort met economyrollback,
seasonal preview-E2E, lint, RLS/revokes en health en daarna de afzonderlijke
productiegate voor 37–41. Release, taggate en post-release health zijn groen.**

Aanvullende visuele eventtranche: **drie afzonderlijke rondes zijn daarna over
Trials, eventkaarten/rewards/ranglijsten en compacte schermen uitgevoerd. De
goedgekeurde eventart loopt nu door in HUD, fasepad, ambient motion, intro,
uitslag, Special Adventure-kaarten/details, Valentijnskaarten, Pride-meter en
ranglijststatussen. Twee afgesneden Trial-iconfragmenten zijn vervangen door
schone transparante Valentijn-/Pride-sprites; Nieuwjaar- en Pride-cutouts kregen
extra veilige randruimte. De vijf geneste eventmappen zijn nu expliciet in de
Flutter assetbundle opgenomen. Productie, servermigraties, appversie en openbare
release blijven hierdoor ongewijzigd. Analyzer en 457/457 tests zijn groen.**

Server- en releasebewijs: **[stagingrun 34072959455](https://github.com/Rakky88/DragonHaven/actions/runs/34072959455)
en [productiemigratie 34073058141](https://github.com/Rakky88/DragonHaven/actions/runs/34073058141)
brachten staging en productie veilig op 41/41 met nul lintfouten. De eerdere
[release v0.05.14](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.14)
wijst exact naar commit `768a6ac48f681d3d9bea2ea63a6048bde4c453d2` en bevat één
`DragonHaven.apk` van 477.701.825 bytes met SHA-256
`5d1bbd939e81665ccfd5904bfa55292f597456f2f6742a76d776c8ba38a8180f`.
Remote grootte en digest zijn gelijk aan lokaal; de versiegebonden en permanente
latest-download geven HTTP 200. De
[taggate 34074223335](https://github.com/Rakky88/DragonHaven/actions/runs/34074223335)
herhaalde productiepreflight, analyzer, 458 tests, vaste signing, Play-ready AAB
en artifactcontrole volledig groen. De
[post-release healthrun 34074693676](https://github.com/Rakky88/DragonHaven/actions/runs/34074693676)
bevestigde Auth en applicatiehealth, uploadde bewijs, sloot een eventueel hersteld
alert en opende geen storingsalert.**

Open meldingsgrens: **privéberichten worden nu merkbaar sneller en retrybaar
opgehaald zolang het appproces leeft en direct bij resume. Gegarandeerde bezorging
nadat Android het proces volledig heeft beëindigd blijft onderdeel van fase 1 en
vereist de nog niet aangeleverde Firebase/FCM-projectconfig.**

Bronnen: [DRAGONHAVEN_AUDIT_2026-08-28.md](DRAGONHAVEN_AUDIT_2026-08-28.md),
[SERVER_IMPROVEMENTS.md](SERVER_IMPROVEMENTS.md),
[DISTRIBUTION.md](DISTRIBUTION.md) en [PUBLIC_LAUNCH.md](PUBLIC_LAUNCH.md)

## Doel van dit document

Dit is de uitvoerbare roadmap voor de punten die na de audit nog openstaan. Het
document maakt per stap duidelijk:

- waarom de stap nodig is en welke andere stappen ervan afhangen;
- wat Codex kan ontwerpen, implementeren, testen en documenteren;
- wat jij in eigen accounts moet beslissen of configureren;
- wanneer de stap aantoonbaar klaar is;
- welke stappen een besloten test, openbare lancering of echte aankopen
  blokkeren.

Dit plan is een levende checklist. Bewijs, besluiten en uitvoeringsdatums horen
na iedere afgeronde stap in dit bestand te worden toegevoegd. Een toekomstige
release blijft aparte, expliciete toestemming vereisen.

## Actuele voortgang per onderdeel

Deze tabel is het korte voortgangsoverzicht. De percentages zijn alleen een
praktische richtwaarde voor de omvang van de mijlpaal; de checkboxes, tests en
bewijslinks verderop bepalen of iets werkelijk klaar is. Bij iedere audittranche
werkt Codex zowel deze tabel als het voortgangslog onderaan bij.

| Onderdeel | Voortgang | Aantoonbaar klaar | Nog door Codex | Nog door jou |
| --- | ---: | --- | --- | --- |
| Google Play-voorbereiding | circa 38% | Permanent package-ID, vaste signingidentiteit, versiecontrole en een ondertekende AAB zijn bewezen. De reproduceerbare appgrootteaudit meet een actuele AAB van 345,00 MiB en 284,99 MiB universele media en legt een gratis optimalisatiepad vast | Beeldpilot en batchoptimalisatie uitvoeren; actuele target-/Play-eisen, storeteksten, graphics, Data Safety-inventaris en rolloutchecklist afronden | Play Console openen/verifiëren; app en Play App Signing aanmaken; pilot visueel goedkeuren; testers, publieke support/privacy-URL's en storeverklaringen beheren |
| iOS/iPhone-voorbereiding | circa 25% | Xcode-project, vaste bundle ID, appicoon, Mac-buildscript en handmatige unsigned macOS-simulatorworkflow bestaan als niet-geactiveerde toekomstbasis | Alleen na een nieuw iOS-besluit de simulatorworkflow bewijzen, audio/notificaties valideren en een veilige deel-/updateroute bouwen | Voorlopig niets; pas bij hervatting Apple Developer/TestFlight, Mac-signing en een echte iPhone inrichten |
| Fase 0 — releasepipeline en secrets | circa 95% | Zes productiesecrets, negen stagingsecrets, APK/AAB-gates, hash- en signingbewijs en openbare release v0.05.21 zijn groen; productie staat gecontroleerd op 57 migraties | Gates per release onderhouden en externe acties periodiek op runtime/security-updates controleren | Repositorytoegang periodiek controleren; originele keystore/recovery veilig dubbel bewaren en mogelijk blootgestelde ontwikkelcredentials roteren |
| Fase 1 — monitoring en incidenten | circa 96% | Firebase Core, Crashlytics, Performance en FCM zijn ingebouwd. Echte stagingcrash/nonfatal gevonden; Performance-trace door Rick bevestigd; gesloten-app push ontvangen en inbox bleef ongelezen. Productieconfiguratie en releasegates zijn bewezen | Representatieve latency-/foutbaseline over een testperiode afronden en persoonlijke alertvoorkeuren verifiëren | Privacy-/Data Safety-verklaringen afronden; gratis projecten blijven onder eigen account zonder billing |
| Fase 2 — staging en E2E | gedeeltelijk | Productie staat op 48 en staging op 49. Sociale, back-up-, trade-, seasonal- en dormant-economycontracten zijn getest. De herziende 100-accountbaseline is groen; de 1000-accountmeting faalt met 47,998% read-time-outs. Alle tijdelijke accounts zijn verwijderd | Time-outfase en belastingoorzaak isoleren; opnieuw 100 en daarna 1000 op het actuele schema meten. De gewone signup-mailbevestigingsflow blijft apart | Piekverbindingen, providerbelasting/egress en representatieve inventarissen ontbreken nog. Meer dan 1000 valt buiten de begrensde workflow |
| Fase 3 — back-up en multi-device | circa 98% | Optimistische revision lock, lokale recovery copy en conflictvenster bestaan; vijf revisies/dertig dagen, automatische 15-minutenback-up plus achtergrondflush zijn gebouwd. De eerste automatisch geplande zondagrestore is groen en rondde de actieve account/back-up/restorerondgang in circa 7,3 seconden af | Later server-owned economievelden van restores afschermen en na fase 4 het terugrol-/duplicatiecontract opnieuw bewijzen | Rick controleert maandelijks het restorebewijs; alleen bij een mislukking of overschrijding van RPO/RTO is een nieuw besluit nodig |
| Fase 4 — server-authoritative economie | gedeeltelijk | Schema 57, gedeelde regels, importvoorbereiding, private eifeiten, duurzame receipt-/snapshotopslag en beschadigd-journalherstel zijn op staging bewezen. De gewone shop en kistweergave zijn lokaal aan de serversessie gekoppeld | De schermkoppeling op staging bewijzen; volledige gameplay, gevalideerde Trials, sociale afwikkeling en migratie/herstel afronden | Vóór live omschakeling migratievenster, spelerscommunicatie en compensatie-/storingsbeleid bevestigen |
| Fase 5 — Google Play Billing | circa 8%, bewust uitgesteld | Product-ID-contract voor valuta en het eenmalige Supporter Pack, idempotente lokale entitlementgrens en uitgeschakelde nepimplementatie houden de architectuur upgradebaar zonder nu kosten te maken | Pas na fase 4 de Billing-SDK, servervalidatie, acknowledgement, refunds/retries en Play-tracktests bouwen | Pas later beslissen wanneer verkoop actief mag worden; merchantprofiel, producten/prijzen/landen, service-identiteit, testers en beleid beheren |
| Fase 6 — support en privacy | circa 68% | Accountverwijdering, veilige supportdiagnostiek en incidentrunbook bestaan. Migratie 33 met service-role-only supportlookup, 30-dagen-inzagelog zonder namen/e-mail/save en dagelijkse fysieke importback-upcleanup is na volledige staging-E2E begrensd op productie toegepast. De testsupportworkflow bewees clientweigering, minimale response, inzagelog/retentie en cleanup | De operationele koppeling van een aangeleverde privacyarme correlation ID aan dezelfde supportcasus oefenen. Na beleid akkoord notification-/Chronicle-retentie migreren en verwijder-E2E uitbreiden | Publiek supportadres, verantwoordelijken/reactietijden, privacy- en verwijderpagina en productietoegang beheren; termijnen voor sociale notificaties en Conclave Chronicle kiezen |
| Fase 7 — capaciteit en rollout | gedeeltelijk | 100 tegelijk actieve accounts zijn gemeten zonder fouten; de 1000-accountmeting is afgekeurd. Exacte synthetische importrestore en de historische SQL-hotfixrepetitie zijn uitgevoerd. Cleanup en nachecks zijn bewezen | Capaciteitsoorzaak isoleren, ontbrekende piekverbindingen/egress en representatieve schrijflast meten; operationele incidentoefening en rolloutdashboard afronden | Capaciteit, budgetalerts, rolloutpercentages en pauzebevoegdheid op meetresultaten kiezen |

### Meetbare checkliststand en eigenaarschap

Onderstaande telling is de objectieve momentopname van de bovenste
checklistregels op **8 september 2026**. Een gedeeltelijk gerealiseerde regel
blijft open totdat ook het laatste acceptatiecriterium bewezen is. Daardoor zijn
de tellingen bewust strenger dan de gewogen voortgangspercentages hierboven:
één grote servermigratie telt hier als één regel, net als één kleine
beheercontrole.

Eigenaars: **C = Codex**, **R = Rick**, **S = samen of een expliciete
start-/acceptatievoorwaarde**. Externe accounts blijven van Rick; Codex bouwt,
test en documenteert zoveel mogelijk gratis. Een pijl betekent dat de volgende
eigenaar pas veilig verder kan nadat de vorige stap is afgerond.

| Onderdeel | C klaar/totaal | R klaar/totaal | S/voorwaarden klaar/totaal | Open regels | Actieve eigenaar en eerstvolgende aantoonbare stap |
| --- | ---: | ---: | ---: | ---: | --- |
| Google Play-voorbereiding | 2/7 | 0/6 | 0/0 | 11 | **C + R parallel:** Codex voert de beeldpilot en store-/Data Safety-inventaris uit; Rick maakt en bezit Play Console, support- en privacy-URL's |
| iOS/iPhone-voorbereiding | 2/8 | 0/5 | 0/4 | 15 | **Gepauzeerd op jouw keuze:** de bronbasis blijft bewaard, maar er is geen iPhone-knop of actieve distributieroute; hervatting begint met een nieuw besluit over TestFlight |
| Fase 0 | 4/4 | 1/4 | 3/3 | 3 | **R:** repositorytoegang controleren, keystore/recovery dubbel veilig bewaren en mogelijk blootgestelde productiecredentials roteren |
| Fase 1 | 7/7 | 5/6 | 1/3 | 3 | **C + R:** Firebaseconfiguratie, echte crash/Performance en push zijn bewezen; Codex werkt de representatieve baseline/alertcontrole af, Rick beoordeelt privacy-/Data Safety-verklaringen |
| Fase 2 | 5/8 | 4/8 | 2/4 | 9 | **R → C:** veilige mailboxroute en 100 synthetische accounts/secretpool; daarna plan-100 en alleen na aparte toestemming run-100 door Codex |
| Fase 3 | 6/7 | 4/5 | 2/3 | 3 | **C + R:** Rick bevestigt conflicttekst; Codex schermt server-owned waarden af tijdens fase 4 en herbewijst daarna restore/duplicatie |
| Fase 4 | 6/16 | 1/6 | 1/4 | 18 | **C:** duurzame sessie en recovery zijn bewezen; nu zichtbare shop/inventaris op staging toetsen en gameplay, Trials, sociale afwikkeling en migratie verder aansluiten |
| Fase 5 | 0/7 | 0/6 | 0/9 | 22 | **Wacht bewust op fase 4 en een gezamenlijke go/no-go:** daarna bouwt Codex Billing; Rick beheert Play-producten, merchantaccount en beleid |
| Fase 6 | 5/6 | 0/4 | 0/3 | 8 | **R + C:** Rick kiest supportkanaal, toegang en retentietermijnen; Codex kan daarna retentiemigraties/verwijder-E2E bouwen. Een echte privacyarme supportmelding is nodig voor de correlation-ID-casusoefening |
| Fase 7 | 1/4 | 0/4 | 0/3 | 10 | **C → S:** 100 actieve accounts zijn gemeten zonder fouten en volledig opgeruimd; de 1000-hermeting loopt. Daarna representatieve gegevens, ontbrekende providerwaarden en een algemene hotfixoefening, gevolgd door gezamenlijke capaciteitskeuzes. |
| **Totaal** | **38/74** | **15/54** | **9/36** | **102 van 164 open** | **62 van 164 checklistregels zijn aantoonbaar afgerond; gedeeltelijke economie-integratie blijft open tot de eindcriteria bewezen zijn** |

De eerstvolgende afhankelijkheden die alleen jij kunt wegnemen zijn daarmee
zichtbaar zonder de lange checklist te lezen. Alles waarvoor geen externe
accountactie of productbesluit nodig is, blijft bij Codex staan en wordt gratis
of lokaal gebouwd waar dat verantwoord kan.

## Uitgerolde releases v0.05.00–v0.05.04

Deze tabel legt vast wat met de expliciet toegestane server- en releaseronde
aantoonbaar is uitgerold en welke niet-blokkerende vervolgpunten nog bestaan.

| Onderdeel | Aantoonbaar uitgerold | Nog door Codex | Nog door jou |
| --- | --- | --- | --- |
| Friend Messages | Vriend-naar-vriendchat, 24-uursweergave, ontvangen toestaan/weigeren, aparte notificatiecategorie, logische deep-link, ongelezen teller, lichte chatpoll en server-side friendship/rate-limitcontrole. De staging-E2E bewijst sturen, ongelezen projectie, lezen en opt-out. | Praktijkgebruik en rate-limittelemetrie blijven volgen; er staat geen releaseblokkade open | Alleen later feedback geven over chat-UX of gewenste limieten |
| Conclaves | 4–20 leden, Public/Request/Invite Only, Flightmaster/Warden/Keeper, 20 emblemen, unieke permanente naam, chat en deelkaarten, Conclave Chronicle, achievement-opt-in, dagelijkse Aerie-bijdrage, 50 levels en 10 Aerie-fasen. De staging-E2E bewijst naamnormalisatie, join, Warden, chat, bijdrage en cleanup. | Balans en schaalgedrag later met echte groepen meten; er staat geen releaseblokkade open | Gewenste Conclave-balans na praktijktest beoordelen |
| Sociale sprites en lokalisatie | Eén eigen berichtenicoon, 20 afzonderlijke emblemen en 10 Aerie-sprites met echte alpha en veiligheidsmarges; alle vaste nieuwe UI-teksten bestaan in acht ondersteunde talen. De productie-APK is op een compacte emulator en met reduced motion gecontroleerd. | Eventuele grotere-tabletpolish meenemen bij een latere visuele tranche | Alleen visuele feedback geven als je later een andere stijl of balans wilt |
| Sociale UI en tutorial | v0.05.01 houdt lange titles en ontdekte-drakentelling op compacte Friends-kaarten leesbaar, plaatst Conclave direct onder het overzicht en geeft Aerie, leden, joinflow en Chronicle een duidelijke hiërarchie. Gedeelde achievements tonen echte badge, naam, omschrijving en gegroepeerde voortgang. De tutorial behandelt in 17 stappen de huidige spelonderdelen en gebruikt gerichte spotlights. | Praktijkfeedback en grotere-tabletpolish later meenemen; er staat geen releaseblokkade open | Alleen visuele of inhoudelijke feedback geven als je later iets anders wilt |
| Serverveiligheid | Migraties 30–32 staan op productie. Directe tabeltoegang is ingetrokken, RLS en afgeschermde RPC's vormen de grens, row locks bewaken capaciteit, de dagledger begrenst Aerie-groei en tijdelijke chatdata heeft vijfminuten-cleanup. De publieke applicatiehealth-RPC leest geen spelerstabellen. Database-lint meldt 0 fouten; Auth health/settings en applicatiehealth geven 200. De veilige testalert is afgeleverd, geverifieerd en gesloten. | Reguliere healthchecks, restorebewijzen, dependencyonderhoud en na Firebase-config een gecontroleerde stagingcrash plus latency-/foutbaseline uitvoeren | Alleen Firebase-project/config aanleveren voor Crashlytics/Performance; voor de huidige healthcheck is niets extra's nodig |

De grootste Aerie-fase begint bij level 46. Met 850 XP per level, maximaal
twintig bijdragen van 10 XP per UTC-dag en een duurzame dagledger zijn daarvoor
minimaal `ceil(45 × 850 / 200) = 192` dagen nodig, ook wanneer leden worden
gewisseld.

## Beoogd einddoel: eerst gratis naar Google Play

Het concrete publicatiedoel is een officiële DragonHaven-release in de
**Google Play Store**. De eerste storeversie kan gratis en zonder in-app
aankopen verschijnen. Betalingen zijn geen voorwaarde voor publicatie en blijven
de uitgestelde, optionele fase 5.

Alle technische keuzes in dit plan moeten daarom verenigbaar blijven met:

- het permanente Android application ID `nl.dragonhaven.app`;
- dezelfde veilig bewaarde release-key en later Play App Signing;
- een door Google Play geaccepteerde, ondertekende Android App Bundle (`.aab`);
- correcte versionName/versionCode-verhogingen en updatecompatibiliteit;
- de op het publicatiemoment vereiste Android target API en actuele
  Play-beleidsregels;
- interne/gesloten testtracks en daarna een gecontroleerde productierollout;
- een store listing, icoon, feature graphic, screenshots en supportcontact;
- een openbare privacyverklaring en accountverwijderpagina;
- eerlijke Data Safety-, doelgroep-, content-rating-, advertentie- en
  app-accessverklaringen;
- beheersbare downloadgrootte en controle op echte Android-toestellen;
- een werkende serverpreflight, monitoring, herstelplan en supportproces.

### Wat Codex voor Google Play voorbereidt

- [x] De release-AAB bouwen en package name, versie, signingcertificaat en hash
  controleren.
- [ ] De CI/releasegate onderhouden en vóór iedere storebuild de actuele Play-
  en target-API-eisen opnieuw controleren.
- [ ] Storeteksten, testnotities, screenshots, feature graphic en technische
  Data Safety-inventaris als concept voorbereiden.
- [ ] Privacy- en accountverwijderlinks technisch in app en website integreren
  zodra jij domein/hosting en definitieve teksten hebt gekozen.
- [x] Appgrootte en assetgroepen reproduceerbaar analyseren. De actuele AAB is
  345,00 MiB en bevat 284,99 MiB universele afbeeldingen/audio;
  `APP_SIZE_AUDIT.md` en `tool/measure_android_artifact_size.ps1` leggen
  bronmeting, actuele officiële Play-grenzen en budgetten vast.
- [ ] De beeldpilot visueel controleren en daarna de grootste categorieën plus
  audio optimaliseren zonder merkbaar kwaliteits-, alpha- of licentieverlies.
- [ ] Problemen uit interne/gesloten tests oplossen en een staged-rollout- en
  rollbackchecklist opleveren.

### Wat jij voor Google Play moet regelen

- [ ] Een Play Console-account openen, eventuele registratiekosten betalen,
  voorwaarden accepteren en identiteit/organisatie verifiëren.
- [ ] DragonHaven in Play Console aanmaken en Play App Signing configureren.
- [ ] De vereiste testers uitnodigen en de testperiode doorlopen die jouw
  actuele account/Console voorschrijft.
- [ ] Definitieve store-, privacy-, doelgroep-, content-rating-, Data Safety-
  en landenverklaringen onder jouw verantwoordelijkheid indienen.
- [ ] Een publiek supportadres, privacy-URL en accountverwijder-URL beheren.
- [ ] De storebuild uploaden, test-/productietrack kiezen en iedere uitrol
  expliciet goedkeuren.

De uitgebreide, levende storechecklist staat in
[PUBLIC_LAUNCH.md](PUBLIC_LAUNCH.md). Vlak vóór indiening moeten de daarin
genoemde externe eisen opnieuw tegen de actuele officiële Google Play-
documentatie worden gecontroleerd; storebeleid kan veranderen.

## Rollen en veilige samenwerking

### Wat Codex doet

Codex kan binnen de repository:

- Flutter-code, Supabase-migraties, server-RPC's en Row Level Security maken;
- unit-, widget-, integratie-, migratie-, herstel- en loadtests toevoegen;
- GitHub Actions, releasepreflights, dashboardspecificaties en runbooks maken;
- logging en monitoring technisch koppelen en gevoelige velden redigeren;
- builds, versies, handtekeningen en release-artifacts controleren;
- privacy-, support-, store- en technische documentatie als concept opstellen;
- na jouw expliciete toestemming migraties toepassen en een release publiceren.

### Wat jij doet

Alleen jij kunt of moet:

- externe accounts openen, betalen, voorwaarden accepteren en identiteit of
  organisatie verifiëren;
- product-, privacy-, doelgroep-, bewaartermijn- en verdienmodelbesluiten nemen;
- productie- en stagingprojecten aanmaken en eigenaar daarvan blijven;
- secrets rechtstreeks in GitHub, Supabase, Firebase of Google Play invoeren;
- toegang, alertontvangers, budgetten en supportverantwoordelijkheid beheren;
- testers uitnodigen en storeverklaringen onder jouw naam indienen;
- iedere productiemigratie en release expliciet autoriseren.

De Android-keystore, databasewachtwoorden, service-role keys, access tokens en
merchantgegevens mogen nooit in Git, dit document of een chatbericht worden
geplaatst. Codex heeft de geheime waarden niet nodig wanneer jij ze rechtstreeks
in de daarvoor bedoelde secret store zet.

### Wat we samen doen

Voor iedere fase bevestigen we eerst de productkeuzes. Codex voert daarna het
technische werk uit en levert het bewijs. Jij controleert het zichtbare gedrag
op een echt toestel en neemt besluiten die gevolgen hebben voor spelers,
privacy, geld of externe diensten.

## Kosten- en bouwbeleid: eerst gratis, zoveel mogelijk door Codex

Voor alle fasen geldt standaard een **free-first** aanpak:

- Codex bouwt zoveel mogelijk zelf in de bestaande Flutter-, Supabase-, GitHub-
  en documentatieomgeving: tests, scripts, dashboardspecificaties,
  healthchecks, supporttools, migraties, server-RPC's, runbooks en rapportages.
- We gebruiken eerst bestaande gratis mogelijkheden en actuele free tiers,
  zolang die veilig, juridisch passend en voldoende betrouwbaar zijn.
- Een betaalde dienst, upgrade of abonnement wordt pas onderdeel van de
  uitvoering wanneer een gratis oplossing aantoonbaar tekortschiet in
  capaciteit, betrouwbaarheid, beveiliging of storevereisten.
- Codex beschrijft vóór zo'n overstap de gratis optie, beperking, betaalde
  optie, verwachte meerwaarde en eventuele migratiemogelijkheid. Jij neemt het
  kostenbesluit en activeert de betaalde dienst zelf.
- Nieuwe onderdelen worden waar praktisch provider-onafhankelijk gebouwd,
  zodat monitoring, e-mail of hosting later kan worden vervangen zonder de
  hele app opnieuw te bouwen.
- We bouwen beveiligingskritieke infrastructuur niet onnodig zelf. Auth,
  betalingstransport, e-mailbezorging en store-receiptcontrole blijven steunen
  op daarvoor bedoelde platformdiensten; Codex bouwt de veilige integratie,
  validatie en eigen spelregels daaromheen.
- Google Play-accountkosten, een eigen domein, eventuele productie-e-mail en
  verbruik boven free-tierlimieten kunnen uiteindelijk niet technisch worden
  weggeprogrammeerd. Zulke kosten worden nooit zonder jouw expliciete keuze
  geactiveerd.
- Echte betalingen worden zo lang mogelijk uitgesteld. Nieuwe economiecode
  wordt wel **payment-ready** ontworpen: duidelijke wallet- en ledgergrenzen,
  stabiele product-ID-koppelingen, idempotente servercommando's, feature flags
  en een vervangbare aankoopprovider. Daardoor kan Billing later worden
  toegevoegd zonder inventory, shops of saves opnieuw te ontwerpen.
- We koppelen nog geen live betaalprovider en maken nog geen verkoopproducten
  actief alleen om de architectuur te testen. De servereconomie krijgt eerst
  tests met een nep-/sandboxprovider. De echte store-integratie volgt pas vlak
  voordat verkoop daadwerkelijk gewenst is, zodat we geen vroege kosten dragen
  of inmiddels verouderde Billing-code langdurig hoeven te onderhouden.

Per mijlpaal rapporteert Codex daarom ook: **huidige kosten**, **verwachte
free-tiergrens**, **signaal om op te schalen** en **goedkopere terugvaloptie**.

## Huidige veilige basis

Deze auditpunten zijn al gerealiseerd en moeten als regressie-eis blijven
bestaan:

- [x] Lokale gameplay blokkeert niet meer op de eerste online refresh.
- [x] De timeout is na gemeten free-tier cold starts verhoogd naar 75 seconden;
  lokale gameplay en navigatie blijven tijdens die online wachttijd beschikbaar.
- [x] Nieuwe accounts tonen e-mailbevestiging en kunnen opnieuw verzenden.
- [x] Trades zijn server-authoritative en gebruiken atomaire reserveringen.
- [x] Chronoshard-variantdata blijft exact behouden in serverinventaris/trades.
- [x] Music-, Portrait- en Title Chests, shop-relics en Twinstar worden
  server-side uit trades geweerd.
- [x] Cloudback-ups gebruiken revisies en lokale herstelkopieën.
- [x] De verplichte Supabase-preflight controleert migration parity, database
  lint, Auth-health/settings en e-mailauth.
- [x] v0.04.06 is geanalyseerd, met 243 tests gecontroleerd en als ondertekende
  APK gepubliceerd.

Bij iedere wijziging aan Auth, trades, relics, inventory, back-ups of releases
moeten de bestaande tests voor deze punten blijven slagen.

## Besluiten die vóór groot ontwikkelwerk nodig zijn

| ID | Besluit van jou | Aanbevolen startpunt | Blokkeert |
| --- | --- | --- | --- |
| B1 | Moet de kernprogressie volledig offline blijven werken? | Lokale weergave mag offline; waardevolle claims en mutaties vereisen verbinding zodra de economie server-authoritative wordt. | Servereconomie |
| B2 | Hoe gaan bestaande saves naar de serverwaarheid? | Eenmalige, gelogde import met limieten en daarna server-lock; nooit stil bestaande voortgang verwijderen. | Servereconomie |
| B3 | Wat gebeurt bij twee apparaten met verschillende saves? | Eerst een expliciet conflictvenster met keuze en herstelkopieën; geen automatische veld-voor-veld-merge in de eerste versie. | Back-up/multi-device |
| B4 | Wanneer mag echte verkoop van gems worden geactiveerd? | Zo laat mogelijk: houd packs uitgeschakeld, bouw de economie nu payment-ready en koppel Billing pas wanneer verkoop echt gewenst is én economie en receiptvalidatie klaar zijn. | Google Play Billing |
| B5 | Welke monitoringstack en wie krijgt alerts? | Begin met de gratis mogelijkheden van Firebase/Supabase/GitHub en een door Codex gebouwde healthcheck; voeg pas een betaalde dienst toe als metingen de noodzaak bewijzen. | Observability |
| B6 | Welke bewaartermijnen gelden voor back-ups, auditlogs en supportdata? | Kies expliciete termijnen vóórdat extra productiegegevens worden opgeslagen. | Back-up, logging, privacy |
| B7 | Welke schaal is de eerste openbare doelgroep? | Begin met een kleine staged rollout en schaal alleen op gemeten gedrag. | Loadtest en capaciteit |

Codex legt ieder besluit na bevestiging vast in de sectie **Besluitenlog** onderaan.

### Concrete keuzehulp voor monitoring (B5)

De aanbevolen kosteloze begininstelling is:

- Firebase [**Spark**](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans)
  zonder betaalmethode, alleen Crashlytics en Performance
  Monitoring; Google Analytics blijft aanvankelijk uit voor minder dataverzameling;
- Rick ontvangt SEV-1/SEV-2 crash- en bereikbaarheidsalerts direct per e-mail;
  niet-kritieke trends worden tijdens testweken eenmaal per dag bekeken;
- geen extra beheerder totdat er een concrete tweede support-/releasebeheerder is;
- Crashlytics en Performance zijn wereldwijde diensten zonder eigen vaste
  DragonHaven-regiokeuze. Als Analytics later nodig is, wordt Nederland als
  rapportageregio gekozen;
- de officiële [Firebase-retentie](https://firebase.google.com/support/privacy)
  accepteren: Crashlytics circa negentig dagen, Performance
  circa dertig dagen voor IP-gekoppelde events en zestig dagen voor installatie-
  gekoppelde/geanonimiseerde performancegegevens;
- privacyarme DragonHaven-supportexports maximaal zeven dagen bewaren en
  incidentbewijs zonder persoonsgegevens maximaal dertig dagen.

Bevestigd op 28 augustus 2026: Spark plus Crashlytics/Performance, Analytics
uit, Rick als enige eerste alertontvanger en bovenstaande termijnen. De gratis
GitHub-healthalert is gebouwd. De Android-SDK-koppeling wacht alleen nog op het
door Rick aangemaakte Firebase-project en `google-services.json`; exacte stappen
staan in `FIREBASE_MONITORING_SETUP.md`.

### Concrete keuzehulp voor back-up en herstel (B6)

De al bevestigde servergrens is vijf revisies en maximaal dertig dagen. Voor de
resterende keuzes is het aanbevolen startpunt:

- handmatige back-up blijft beschikbaar; daarnaast automatisch na een
  betekenisvolle voortgangsmutatie, maximaal eenmaal per vijftien minuten en
  alleen ingelogd wanneer geen conflict of upload actief is;
- ook proberen bij veilig naar achtergrond gaan; offline wijzigingen wachten
  zonder gameplay te blokkeren tot de volgende verbinding;
- **RPO:** maximaal vijftien minuten online voortgang sinds de laatste geslaagde
  automatische back-up; offline is het verliesvenster noodgedwongen tot de
  eerstvolgende verbinding;
- **RTO:** een speler kan een van de vijf revisies binnen vijftien minuten zelf
  herstellen; een supportherstel heeft als eerste doel vier uur tijdens
  beschikbare supporturen;
- wekelijks een geautomatiseerde restore-integriteitstest op staging en
  maandelijks handmatig bewijs controleren; Rick is in eerste instantie de
  menselijke controle-eigenaar.

Bevestigd op 28 augustus 2026: automatische back-up met vijftienminutengrens,
bovenstaande RPO/RTO en Rick als maandelijkse controle-eigenaar. De automatische
trigger en wekelijkse stagingtest zijn gebouwd. De eerste geplande zondagrun
[`33305301266`](https://github.com/Rakky88/DragonHaven/actions/runs/33305301266)
slaagde op 30 augustus 2026: de actieve bevestigde-account-, back-up- en
restorerondgang duurde circa 7,3 seconden en het privacyarme bewijsartifact
wordt dertig dagen bewaard.

## Prioriteiten en releasepoorten

- **P0 — eerst:** releasepipeline, observability en aparte staging.
- **P1 — vóór brede publieke lancering:** multi-device veiligheid,
  server-authoritative economie, supportdiagnostiek en realistische loadtests.
- **P1 voor betalingen:** Google Play Billing plus server-side
  receiptvalidatie; zonder dit blijven echte aankopen uitgeschakeld.
- **P2 — daarna:** operationele verfijning, automatische capaciteitsrapportage
  en verdere schaaloptimalisatie.

Een besloten test kan met de huidige offline-first grens doorgaan. Een brede
publieke lancering hoort niet door te gaan zolang P0 niet klaar is en de
offline-economierisico's niet expliciet zijn opgelost of geaccepteerd. Echte
gemverkoop mag nooit worden aangezet vóór fase 5 volledig slaagt.

## Fase 0 — releasepipeline en eigendom van secrets

**Prioriteit:** P0  
**Omvang:** klein  
**Reden:** de v0.04.06-tagworkflow kon de tijdelijke Play Store-AAB niet bouwen
omdat de GitHub-repository geen Supabase- en signingsecrets bevatte. De lokale
APK en productiepreflight waren wel geldig.

### Codex

- [x] Voeg een afzonderlijke handmatig startbare pipelinecontrole toe die
  ontbrekende secretnamen vroeg en zonder waarden te loggen meldt.
- [x] Controleer dat de CI-AAB dezelfde package name en signingcertificaat-
  fingerprint gebruikt als de gepubliceerde APK.
- [x] Laat een succesvolle workflow de versie, versionCode, commit, AAB-hash,
  migratie-uitkomst en certificaatfingerprint als verificatierapport bewaren.
- [x] Documenteer herstel bij een mislukte serverpreflight of signingcheck.

### Jij

- [x] Plaats rechtstreeks in GitHub Actions Secrets:
  `DRAGONHAVEN_KEYSTORE_BASE64`, `DRAGONHAVEN_KEYSTORE_PASSWORD`,
  `DRAGONHAVEN_KEY_ALIAS`, `DRAGONHAVEN_KEY_PASSWORD`,
  `SUPABASE_ACCESS_TOKEN` en `SUPABASE_DB_PASSWORD`.
- [ ] Controleer dat alleen noodzakelijke beheerders repository- en
  secrettoegang hebben.
- [ ] Bewaar de originele keystore en recovery-informatie op minimaal twee
  versleutelde, afzonderlijke locaties.
- [ ] Roteer productiecredentials die tijdens ontwikkeling mogelijk buiten de
  bedoelde secret store zijn gebruikt.

### Samen klaar wanneer

- [x] Een handmatige CI-run analyse, alle tests, serverpreflight en een
  ondertekende `DragonHaven.aab` volledig groen afrondt.
- [x] Het signingcertificaat exact overeenkomt met bestaande DragonHaven-
  releases en geen secretwaarde in logs of artifacts staat.
- [x] Het verificatierapport aan de run gekoppeld is.

Bewijs: handmatige GitHub Actions-run
[`33177281257`](https://github.com/Rakky88/DragonHaven/actions/runs/33177281257)
bouwde zonder publicatie versie `0.04.06` (`versionCode 10039`) met commit
`ade9b71939ee642290374a927f2d5f6df3935491`. De AAB-hash was
`C68D448229800BF6663E3CB33EC297032D6D3DA94B3E146B66D4F2B691C21C5E` en de
signingfingerprint kwam overeen met
`477C5A5D7453384CA756265E77AF97D5A002A907177CCD2D9065A9BEC3414942`.
Het tijdelijke bewijsartifact verloopt op 04-09-2026; de run en dit plan
bewaren de controle-uitkomst blijvend.

## Fase 1 — observability, alerts en incidentbasis

**Prioriteit:** P0  
**Omvang:** middelgroot  
**Afhankelijk van:** B5 en B6

### Codex

- [x] Koppel crash- en performance-monitoring met buildversie, platform en een
  willekeurige technische installatie-ID; log geen wachtwoorden, tokens,
  volledige saves, e-mailadressen of zichtbare keepernamen. Firebase Core,
  Crashlytics en Performance zijn ingebouwd en bewezen; de SDK beheert zijn
  technische installatie-identiteit. Geen account-/correlation-ID in aangepaste
  Firebase-attributen. Zie `FIREBASE_MONITORING_SETUP.md`.
- [x] Voeg veilige request/correlation IDs toe aan Auth-, backup-, Friends-,
  Trade- en Group Adventure-paden.
- [x] Maak dashboards of dashboardspecificaties voor
  (`OBSERVABILITY_BASELINE.md`):
  - Auth-foutpercentage, verificatie en loginlatency;
  - RPC-foutpercentage en p50/p95/p99-latency;
  - trade- en Group Adventure-fouten;
  - databaseverbindingen, CPU, opslag en egress;
  - back-upsuccessen, revision conflicts en restore-uitkomsten;
  - actieve appversies en client/servercompatibiliteit.
- [x] Voeg synthetische healthchecks toe voor publieke Auth.
- [x] Activeer de veilige, read-only applicatiecheck. Migratie 32, de
  privacyvrije RPC, parsertests, workflowintegratie en exact begrensde
  productiemigratie zijn op staging en productie bewezen; de uurlijkse en
  post-release controles zijn groen.
- [x] Schrijf een incidentrunbook met ernstniveaus, triage, rollback,
  communicatie en controle na herstel.
- [x] Voeg tests toe die bewijzen dat gevoelige data wordt geredigeerd.

### Jij

- [x] Maak en bezit het gekozen monitoring/Firebase-project en registreer
  `nl.dragonhaven.app`.
- [x] Kies in eerste instantie het gratis plan en zet budgetmeldingen aan waar
  de provider dat ondersteunt; een upgrade vereist een apart besluit.
- [x] Kies wie waarschuwingen ontvangt, tijdens welke uren en via welk kanaal.
- [x] Stel maandbudget, datalocatie en bewaartermijn in.
- [ ] Beoordeel of diagnostische gegevens en toestemming in de
  privacyverklaring/Data Safety moeten worden aangepast.
- [x] Geef alleen projectconfiguratie via veilige configuratie of secret stores;
  deel geen beheer- of servicecredentials in de app.

### Samen klaar wanneer

- [ ] Een gecontroleerde stagingfout binnen de afgesproken tijd zichtbaar is
  met versie en correlation ID, zonder persoonsgegevens of secrets.
- [x] Een testalert aankomt bij de juiste ontvanger en het runbook naar de
  oorzaak en herstelactie leidt. De handmatig-only workflow, exacte
  bevestigingspoort, `[DRILL]`-scheiding, toegewezen ontvanger, versie/correlation
  ID, runbooklink, automatische contractcontrole en privacyarm bewijs zijn in
  [run 33435265676](https://github.com/Rakky88/DragonHaven/actions/runs/33435265676)
  bewezen. De melding kwam als
  [testissue #1](https://github.com/Rakky88/DragonHaven/issues/1) aan en is na
  verificatie automatisch gesloten.
- [ ] Er gedurende minimaal één testperiode een bruikbare latency- en
  foutbaseline is vastgelegd voordat vaste alarmdrempels worden gekozen.

## Fase 2 — gescheiden staging, end-to-endtests en belastingtests

**Prioriteit:** P0  
**Omvang:** groot  
**Afhankelijk van:** fase 0 en bij voorkeur fase 1

### Codex

- [x] Maak omgevinggestuurde configuratie voor lokaal, staging en productie,
  zonder productiecredentials in testbuilds.
- [x] Laat lokale tests en GitHub Actions zoveel mogelijk werk afvangen voordat
  een externe stagingresource wordt belast.
- [x] Maak reproduceerbare stagingmigraties en veilige tweepersoons-testdata met
  opruimlogica voor Friends, trades en Group Adventure-wachtlobby's.
- [ ] Automatiseer minimaal deze volledige flow:
  1. [x] signup en bevestigingsmail aanvragen;
  2. [ ] e-mailbevestiging volledig automatiseren — de eerste staginglink is
     veilig handmatig bevestigd zonder mailboxwachtwoord te delen;
  3. [x] eerste login en idempotente accountbootstrap;
  4. [x] cloudback-up, restore en weigering van een verouderde revisie;
  5. [x] Friends request en acceptatie;
  6. [x] trade reserveren, accepteren, afronden en inventarisbehoud bewijzen;
  7. [x] Group Adventure aanmaken, lijsten, deelnemen en veilig verlaten;
  8. [x] Group Adventure starten, afronden en reward-idempotentie bewijzen.
- [x] Voeg scenario's toe voor timeout, offline/online wissel, verlopen sessie,
  dubbele request, appherstart en een halverwege mislukte actie.
- [x] Maak een loadtestprofiel dat snapshotpolling en echte gebruikersacties
  combineert; geen onrealistische constante spam. Het lokale profiel gebruikt
  unieke bevestigde accounts, zestig seconden ramp-up, acht tot twintig seconden
  think time en een vaste mix van snapshot, profiel, back-uphistorie, Group
  Adventures en Conclaves. Productie en aantallen buiten 100/1.000 worden hard
  geweigerd; zie `STAGING_LOAD_TEST.md`.
- [ ] Laat de test eerst op 100 en daarna 1.000 gelijktijdige synthetische
  gebruikers draaien. Test 5.000–10.000 pas na kosten- en capaciteitsgoedkeuring.
- [ ] Rapporteer p95/p99, foutpercentages, databasebelasting, verbindingen,
  egress en gevonden query/indexproblemen.

### Jij

- [x] Maak een afzonderlijk Supabase-stagingproject onder jouw account.
- [x] Start daarvoor met de gratis tier zolang de geplande tests binnen de
  actuele limieten passen.
- [ ] Configureer een staging-e-mailroute/inbox waarmee bevestigingslinks veilig
  geautomatiseerd kunnen worden.
- [ ] Maak vóór de eerste echte belastingstest 100 unieke, bevestigde,
  niet-persoonlijke stagingaccounts en zet de compacte credentialpool uitsluitend
  als `STAGING_LOAD_CREDENTIALS_JSON` in de GitHub Environment `staging`.
- [x] Richt afzonderlijke stagingaliases in en bevestig beide testaccounts
  zonder het mailboxwachtwoord met Codex te delen.
- [x] Voeg stagingcredentials rechtstreeks als afgeschermde GitHub Environment
  Secrets toe en vereis zo nodig jouw goedkeuring voor runs.

De eerste geïsoleerde stagingrun
[`33176572637`](https://github.com/Rakky88/DragonHaven/actions/runs/33176572637)
is volledig geslaagd: secret- en production-safetychecks, 20 migraties,
Auth/configuratie, schemalint, publieke serverpreflight, analyzer, 252 tests,
APK-build en artifactupload waren groen. Dit was het bewijs voor de publieke
stagingbasis, nog zonder ingelogde sociale acties.

De bevestigde-accountworkflow
[`33180648232`](https://github.com/Rakky88/DragonHaven/actions/runs/33180648232)
is daarna volledig geslaagd. Hij bewees echte password-login met bevestigde
e-mail, idempotente accountbootstrap, profielread, cloud-back-up en restore,
weigering van een stale revisie en het intrekken van de testsessie. Daarna
slaagden analyzer, alle 252 tests, staging-APK en artifactupload opnieuw. De
workflow bewaart geen e-mailadres, wachtwoord, token of user-id in het rapport.

Na bevestiging van het tweede testaccount slaagde de sociale workflow
[`33182884493`](https://github.com/Rakky88/DragonHaven/actions/runs/33182884493)
volledig. De run bewees Friends request/acceptatie en wederzijdse zichtbaarheid,
een atomaire Wooden Chest-ruil met inventarisbehoud, plus Group Adventure
aanmaken/lijsten/deelnemen/verlaten. Tijdelijke vriendschap, trade en wachtlobby
zijn veilig opgeruimd en beide sessies ingetrokken. Analyzer, alle 252 tests,
staging-APK en het bewijsartifact waren opnieuw groen. De workflow bewaart ook
hierbij geen e-mailadres, wachtwoord, token, keepercode of user-id.

Na expliciete toestemming voor een staging-only tijdregeling slaagde ook
[run 33196707499](https://github.com/Rakky88/DragonHaven/actions/runs/33196707499).
De afgeschermde workflow weigerde het productieproject hard, normaliseerde
uitsluitend de tijdelijke synthetische lobby naar de twee beschikbare accounts,
startte vervolgens via de gewone server-RPC en liet alleen de eindtijd verlopen.
Beide deelnemers ontvingen dezelfde serverreward, een tweede acknowledgement
voegde niets toe en de fixture plus testreward zijn weer opgeruimd. Analyzer,
260 tests, staging-APK en bewijsartifact waren groen.

- [ ] Bepaal het testbudget en keur iedere test boven 1.000 gelijktijdige
  gebruikers vooraf goed.
- [ ] Bevestig dat synthetische accounts en testmailadressen geen echte
  persoonsgegevens bevatten.

### Samen klaar wanneer

- [ ] De volledige flow herhaalbaar slaagt op een lege stagingdatabase.
- [x] Een migratie vanaf de vorige productieschemaversie ook slaagt.
- [x] Foutscenario's geen dubbele reward, item, trade of Group Adventure
  veroorzaken.
- [ ] De afgesproken belastingdoelstelling binnen vastgelegde fout- en
  latencygrenzen blijft en productie nooit door de test wordt belast.

## Fase 3 — cloudback-up, restore en multi-device conflicten

**Prioriteit:** P1  
**Omvang:** groot  
**Afhankelijk van:** B3, B6 en fase 2

### Aanbevolen productmodel

Gebruik eerst optimistische revisievergrendeling. Als apparaat A en B vanaf
dezelfde cloudrevision uiteenlopen, mag het tweede apparaat niet stil het eerste
overschrijven. Toon datum, apparaat, revision en een veilige voortgangssamenvatting
en laat de speler expliciet kiezen. Maak vóór iedere keuze een lokale
herstelkopie. Een automatische merge komt pas later, per datadomein, nadat de
economie server-authoritative is.

### Codex

- [x] Breid back-ups uit met save-ID, parent revision, apparaat-ID,
  clientversie, schema-versie en servertijd.
- [x] Laat de server een verouderde `expectedRevision` atomair weigeren en
  retourneer een specifiek conflict in plaats van een algemene fout.
- [x] Bouw een conflictvenster met drie veilige acties: cloud bekijken,
  huidige lokale staat behouden/uploaden na bevestiging, of cloud herstellen.
- [x] Houd een beperkt aantal herstelbare serverrevisies bij volgens de gekozen
  bewaartermijn.
- [ ] Splits later server-owned economievelden af zodat een oude save nooit
  valuta of items kan terugzetten of dupliceren.
- [x] Maak automatische integratietests met twee apparaten en overlappende
  uploads/restores.
- [x] Voeg een periodieke restore-test en controle op save-integriteit toe.

Implementatiebewijs: migraties
`202608280022_cloud_save_revision_history.sql` en
`202608280023_fix_cloud_save_history_conflict_target.sql` bewaren de huidige
plus vier vorige revisies, verwijderen eerdere revisies per account, verwijderen
fysiek alle historie ouder dan dertig dagen via een dagelijkse databasejob en
houden directe tabeltoegang gesloten. De app toont de revisiegeschiedenis met
save-ID, parent revision, apparaat, appversie, saveschema en servertijd. Een
oude revisie herstellen bewaart eerst lokaal herstel; expliciet **Cloud
vervangen** vereist een tweede bevestiging en laat de vorige serverkopie in de
herstelgeschiedenis staan. Unit/integratietests simuleren overlappende apparaten,
stale writes, oudere restore en daarna veilig doorback-uppen.

### Jij

- [x] Kies bewaartermijn en aantal herstelrevisies.
- [x] Kies of back-up handmatig blijft of ook automatisch op veilige momenten
  gebeurt.
- [ ] Bevestig de conflictteksten en welke voortgangssamenvatting voor spelers
  begrijpelijk is.
- [x] Kies RPO en RTO: hoeveel voortgang maximaal verloren mag gaan en binnen
  welke tijd herstel mogelijk moet zijn.
- [x] Wijs iemand aan die periodieke restore-resultaten controleert.

### Samen klaar wanneer

- [x] Twee apparaten nooit ongemerkt elkaars voortgang overschrijven.
- [ ] Iedere restore een recovery copy achterlaat en server-owned waarde niet
  kan terugdraaien of verdubbelen.
- [x] Een echte stagingrestore volgens het runbook slaagt en de gemeten
  hersteltijd is vastgelegd. De eerste automatisch geplande zondagrun
  `33305301266` rondde de actieve rondgang in circa 7,3 seconden af.

## Fase 4 — server-authoritative economie

**Prioriteit:** P1 en verplicht vóór echte aankopen  
**Omvang:** extra groot; uitvoeren in meerdere compatibele releases  
**Afhankelijk van:** B1, B2, B6, fase 1–3

### Vaste technische regels

Iedere waardevolle actie gebruikt een ingelogde server-RPC met een unieke
idempotency key. De server controleert ownership en limieten, rolt randomness
op de server en schrijft resultaat plus auditregel in één transactie. Een
herhaalde request retourneert exact hetzelfde resultaat. De client animeert
alleen het serverresultaat en bezit nooit een service-role key.

### Deel 4A — fundament en migratie

#### Codex

- [x] Ontwerp servertabellen voor wallet, item/egg/chest instances, dragons,
  rewardclaims, idempotency records en een append-only economy auditlog.
  Migratie 37 gebruikt de bestaande revisioned wallet-, egg- en dragontabellen
  en voegt de ontbrekende instance-, claim-, request- en ledgertabellen dormant
  toe; het volledige contract staat in `SERVER_AUTHORITATIVE_ECONOMY.md`.
- [x] Maak in wallet/ledger onderscheid tussen bron en mutatietype, zodat later
  een gevalideerde storeaankoop kan worden toegevoegd zonder huidige balances
  of saves te migreren; sla nog geen onnodige betaalgegevens op. De kandidaat
  bewaart bron, mutatietype, signed delta en nieuw saldo, maar geen e-mail,
  kaartgegevens, purchase token of raw receipt.
- [x] Definieer een kleine aankoopprovider-interface en uitgeschakelde
  nepimplementatie voor tests. De echte Google Play-implementatie blijft uit.
- [ ] Koppel de provider later pas via een feature flag aan de zichtbare shop,
  nadat de serverwallet en receiptvalidatie bestaan.
- [x] Voeg constraints, RLS, rate limits en serverfuncties toe. Migratie 37
  begrenst identifiers/JSON, trekt alle directe clienttabelrechten in, zet RLS
  aan, rate-limit alleen nieuwe requests en bevat private fail-closed helpers.
  De openbare app krijgt uitsluitend een read-only contractprojectie.
- [ ] Rond het versieerbare eenmalige importpad af. Protocol/saveversie,
  validatie, plausibiliteitslimieten, privacyarme rapportage, SHA-256-bewijs,
  server-lock en een private herstelkopie van dertig dagen zijn gebouwd;
  migratie en rapportcoherentie zijn op staging bewezen. De gecontroleerde
  synthetische importrollback is nu ook bewezen (`34120524533`), inclusief
  volledige rij-/hashequivalentie en weigering van nieuwere voortgang. De
  operationele herstelprocedure voor echte accounts blijft open.
- [x] Maak een compatibiliteitsvenster zodat oude clients geen ongeldige nieuwe
  mutaties kunnen doen. `legacy_client`, `shadow` en `server`, protocolversie,
  minimum build en een globale noodschakelaar zijn gebouwd; standaard kan geen
  enkele keeper de nieuwe mutatiehelpers gebruiken.

#### Jij

- [x] Kies het importbeleid voor bestaande spelers: volledig vertrouwen,
  plausibiliteitslimieten of handmatige beoordeling bij uitzonderingen.
  Bevestigd onder B2: plausibiliteitslimieten, gelogde eenmalige import en daarna
  server-lock, zonder bestaande voortgang stil te verwijderen.
- [ ] Bevestig welke voortgang nooit mag worden afgenomen zonder menselijke
  controle.
- [ ] Keur migratievenster, spelerscommunicatie en rollbackbeleid goed.

### Deel 4B — valuta, shops en chests

#### Codex

- [ ] Verplaats coin/gemmutaties, shopaankopen, chestownership, chestopening,
  pity, collection caps en relicdrops naar atomaire RPC's.
  Migratie 39 koopt vanity-kisten; 45 opent alle kisttypen, bepaalt inhoud/pity
  en bewaart vaste relicwaarden. Beide zijn dormant op staging en productie
  bewezen. Migratie 47 voor gewone meubels en winkelrelics staat eveneens op beide omgevingen. Treats,
  kamerontgrendeling en andere acties bestaan ook in de gedeelde canonieke
  spelregels. De zichtbare winkel/kistkoppeling is met echte servers op staging
  bewezen (34281388567); volledige gameplaykoppeling, import en cutover blijven open.
- [ ] Laat alle random rolls en collection checks op de server plaatsvinden.
  De drie collection caps van de eerste aankoop-RPC worden server-side onder
  een keeperlock gecontroleerd; migratie 45 bepaalt ook alle chestinhoud op de server.
  Randomness buiten kisten en de uiteindelijke cutover blijven open.
- [ ] Test replay, dubbele taps, timeouts, reconnects en aangepaste clients.
  Fundament-replay/conflict/rate limit/oud-client/rollback is op staging groen.
  De lokale clienttest bewijst één request-ID na verloren antwoord/reconnect en
  twee gelijktijdige taps. Migratie-39-E2E en 45-replay/rollback zijn op staging
  groen; de nieuwe intent-store bewaart de UUID door een appherstart heen.

#### Jij

- [ ] Bevestig economieprijzen, compensatiebeleid bij fouten en of er een
  onderscheid tussen verdiende en gekochte gems nodig is.

### Deel 4C — eggs, dragons, relics en progressie

#### Codex

- [ ] Verplaats eggtoekenning/incubatie/hatch, dragonownership, XP, levels,
  evolution, expertise en economisch relevante achievements naar de server.
  De gedeelde regels bestaan; de ei-/Altar-/drakenschermen gebruiken nu de
  canonieke stagingserver. Proef 34286596835 bewijst de echte acties, verborgen
  ei-informatie en herstel na een verloren antwoord. Volledige gameplay,
  scorevalidatie en productiemigratie blijven de open afronding.
- [ ] Bewaar Chronoshard-percentage en Twinstar-equip atomair en uniek.
  De bestaande vaste percentages en alle vier broches zijn in de stagingclient
  getypeerd en gevalideerd; dezelfde servertransactie bewaart de equipwissel.
  De echte UI-proef bewijst één brocheplek. Productiecutover staat nog open.
- [ ] Voorkom dat een oude cloudsave een uitgebroed ei of verbruikte relic
  terugbrengt.
  De geïsoleerde lane leest geen lokale save en herstelt dezelfde request-ID
  na herstart. De bestaande autoriteits-/importfences blijven actief; de
  uiteindelijke omzetting van echte spelers is nog niet uitgevoerd.

#### Jij

- [ ] Beslis welk spelgedrag tijdens een serverstoring alleen bekeken mag worden
  en welke acties later in een wachtrij mogen.

### Deel 4D — rewards en dagelijkse limieten

#### Codex

- [ ] Verplaats Adventure-, Trial-, minigame-, achievement- en dagelijkse
  claims naar servergestuurde, eenmalige rewardrecords.
  Gewone Adventure-starts en claims zijn vanuit de echte staging-UI bewezen
  (34289398487): ook na een verloren antwoord één chest/XP/expertisegrant.
  Trialbewijzen, sociale/seasonal claims en productiecutover blijven open.
- [ ] Laat de server claimtijd, daggrens en relevante scorebewijsgegevens
  valideren.
  De echte Adventure-proef weigert een vroege claim en wacht de serverdeadline
  af. De algemene daggrens en gevalideerde minigametranscripten zijn nog open.
- [ ] Voeg misbruikdetectie toe voor onmogelijke frequenties, replays en
  afwijkende rewardpatronen zonder automatisch legitieme spelers te straffen.

#### Jij

- [ ] Bepaal wanneer een afwijking alleen wordt gelogd, tijdelijk wordt
  geblokkeerd of door support wordt beoordeeld.

### Samen klaar wanneer

- [ ] Een aangepaste of oude client geen coins, gems, items, dragons of rewards
  kan creëren, verdubbelen of terugzetten.
- [ ] Alle dubbele/vertraagde requests idempotent zijn.
- [ ] Iedere waardemutatie via user UUID, request ID, bron, verschil en
  servertijd controleerbaar is.
- [ ] Een staged migratie van representatieve v0.04.06-saves zonder verlies
  slaagt en rollback aantoonbaar werkt.

## Fase 5 — Google Play Billing en server-side aankoopvalidatie

**Prioriteit:** P1 zodra echte aankopen gewenst zijn  
**Omvang:** groot  
**Afhankelijk van:** B4 en een afgeronde fase 4  
**Huidige veilige toestand:** currency packs blijven uitgeschakeld.

Deze fase wordt bewust pas gestart wanneer jij daadwerkelijk binnen afzienbare
tijd wilt gaan verkopen. De voorbereidende interfaces, ledgervelden en
idempotency uit fase 4 maken die late koppeling mogelijk. Tot dat moment blijven
alle betaalfeature-flags uit, bestaan er geen koopbare liveproducten en is er
geen betaalprovider nodig voor normaal spel of tests.

### Startcriteria voor deze uitgestelde fase

- [ ] De server-authoritative economie en migratie van bestaande spelers zijn
  aantoonbaar stabiel.
- [ ] Jij hebt besloten dat echte verkoop voldoende voordeel biedt tegenover
  commissie, support, administratie en juridische verplichtingen.
- [ ] Producten, prijzen, landen, refundbeleid en testgroep zijn inhoudelijk
  vastgesteld.
- [ ] Privacy, support, monitoring en incidentafhandeling zijn klaar voor
  financiële transacties.
- [ ] De op dat moment actuele Google Play Billing-eisen zijn opnieuw
  gecontroleerd; we implementeren niet jaren vooraf tegen mogelijk verouderde
  API's.

### Codex

- [ ] Integreer Google Play Billing met product-ID's uit configuratie.
- [ ] Stuur purchase tokens via een beveiligde serverfunctie naar de Google Play
  Developer API; vertrouw nooit een clientmelding als aankoopbewijs.
- [ ] Verwerk aankoop, acknowledgement en gemcredit idempotent.
- [ ] Ondersteun pending, cancelled, duplicate, already-owned, offline retry,
  reinstall/restore, refund en revocation.
- [ ] Voeg Real-time Developer Notifications of een periodieke
  reconciliatietaak toe voor refunds en terugboekingen.
- [ ] Maak test- en supportinformatie zonder volledige tokens bloot te geven.
- [ ] Test alle aankoopstaten in een Play-testtrack vóór activatie.

### Jij

- [ ] Open en verifieer Play Console plus merchant/betalingsprofiel.
- [ ] Maak definitieve product-ID's, prijzen en landen aan; product-ID's later
  niet lichtvaardig wijzigen.
- [ ] Maak een minimaal bevoegde service-identiteit voor aankoopvalidatie en
  plaats de credentials rechtstreeks in serversecrets.
- [ ] Configureer licentietesters en interne/gesloten testtracks.
- [ ] Beslis over refunds, minderjarigen, belasting, consumentenvoorwaarden en
  support; laat juridische/fiscale keuzes zo nodig professioneel beoordelen.
- [ ] Vul de store- en Data Safety-informatie naar waarheid in.

### Samen klaar wanneer

- [ ] Testaankoop, pending betaling, annulering, dubbele callback, reinstall,
  refund en revocation allemaal aantoonbaar correct werken.
- [ ] Gems exact één keer worden toegekend en bij een geldige terugboeking
  volgens het gekozen beleid worden verwerkt.
- [ ] Geen servicecredential of volledig purchase token in app, log of Git staat.
- [ ] Packs pas na expliciete go/no-go zichtbaar en koopbaar worden.

## Fase 6 — support, privacy en operationeel beheer

**Prioriteit:** P1 vóór brede publieke lancering  
**Omvang:** middelgroot  
**Afhankelijk van:** B6 en fase 1

### Codex

- [x] Bouw een minimaal supportzoekpad op Keeper ID naar interne user UUID,
  accountstatus, save-/clientversie en geaggregeerde back-up-/tradestatus;
  gebruik nooit alleen de zichtbare keepernaam. Productiemigratie 33 doet dit
  zonder e-mail, naam, savebody of inventory. Correlation IDs blijven bewust
  afkomstig uit de privacyarme clientexport omdat de server ze niet bewaart.
- [x] Maak een veilige diagnostiekexport waarin tokens, e-mail en volledige
  inventory standaard ontbreken.
- [x] Documenteer procedures voor verloren account, niet ontvangen e-mail,
  mislukte trade, back-upconflict, verwijdering, refund en vermoed misbruik in
  `SUPPORT_PRIVACY_OPERATIONS.md`, inclusief minimale intake, verboden data,
  beslisgrenzen en huidig/toekomstig aankoopgedrag.
- [x] Voeg least-privilege rollen en logging van supportinzage toe zodra een
  supporttool wordt gebouwd. Productiemigratie 33 staat alleen `service_role`
  toe, vereist casusnummer/operatoralias/vaste reden en bewaart dertig dagen een
  append-only log met gehashte Keeper ID; apply, lint en preflight zijn op
  staging bewezen in run 33435243659 en op productie in run 33562064314.
- [x] Bouw een handmatige staging-only testsupportflow met exacte
  bevestigingstekst, dubbele productieblokkade, een normale-clientweigering,
  minimale-responsecontrole, 30-dagen-logcontrole, tijdelijke cleanup-sentinel
  en een privacyarm bewijsartefact. Run 33438895977 bewees alle contracten en
  uploadde een gecontroleerd artefact van 413 bytes zonder Keeper ID, UUID,
  e-mail, token, wachtwoord of responsebody. De parallelle volledige gate
  33438894645 bewees analyzer, tests, sociale E2E en staging-APK.
- [ ] Stem verwijdering/retentie af tussen Auth, profiel, saves, auditlogs,
  monitoring en aankoopadministratie. De huidige bewaarmatrix is vastgelegd:
  chat-, cloud- en accountdeletepaden zijn aantoonbaar. Migratie 33 sluit op
  productie de ontbrekende fysieke purge van 30-dagen-importback-ups.
  Acknowledged/oude unacknowledged sociale notificaties, Conclave Chronicle en
  toekomstige aankoopadministratie vereisen nog beleid en/of migratie.

### Jij

- [ ] Kies een supportadres, verantwoordelijke personen en reactietijden.
- [ ] Bepaal wie productiegegevens mag zien en trek toegang direct in wanneer
  die niet meer nodig is.
- [ ] Stel privacyverklaring, accountverwijderpagina en interne
  bewaartermijnen vast; jij blijft verantwoordelijk voor de inhoud.
- [ ] Beheer verzoeken van spelers en eventuele wettelijke bewaarplichten.

### Samen klaar wanneer

- [ ] Een testsupportmelding vanaf Keeper ID via correlation ID naar de juiste
  serveractie kan worden onderzocht zonder onnodige persoonsgegevens. De
  production-blocked Keeper-ID-lookup, inzagelog en cleanup zijn op staging
  bewezen; alleen de operationele koppeling met een aangeleverde privacyarme
  correlation ID moet nog als volledige casusoefening worden vastgelegd.
- [ ] Verwijdering en retentie in app, server, monitoring en documentatie niet
  met elkaar in tegenspraak zijn.
- [ ] De meest waarschijnlijke incidenten minimaal eenmaal als oefening zijn
  doorlopen.

## Fase 7 — capaciteitsbewijs en gecontroleerde lancering

**Prioriteit:** P1 vóór brede publieke lancering, daarna doorlopend  
**Omvang:** middelgroot na voltooiing van eerdere fasen

### Codex

- [ ] Zet gemeten stagingresultaten om in capaciteitsschattingen, index- of
  queryverbeteringen en concrete alarmdrempels.
- [ ] Breid de releasegate uit met staging-E2E, migratietest, serverpreflight,
  artifactversie, handtekening, hash en client/servercompatibiliteit.
- [x] Maak een rollback/hotfix-runbook voor app én database; destructieve
  databasemigraties vereisen een apart herstelplan. `ROLLBACK_HOTFIX_RUNBOOK.md`
  legt app- en database-fix-forward, versie/signing/servergates, herstelbewijs,
  privacygrenzen en de ontbrekende algemene production kill-switch expliciet
  vast. De eerste niet-destructieve stagingoefening blijft open.
- [ ] Maak een rolloutdashboard per appversie en bewaak oude clients.

### Jij

- [ ] Kies Supabase-capaciteit en budgetalerts op basis van metingen, niet op
  gokwerk.
- [ ] Start met een kleine staged rollout en keur iedere vergroting apart goed.
- [ ] Houd support, Auth, e-mail, crashes, RPC's, database en kosten tijdens de
  rollout actief in de gaten.
- [ ] Bepaal wie een rollout kan pauzeren en wie over rollback beslist.

### Samen klaar wanneer

- [ ] Iedere release een volledig bewaard verificatierapport heeft.
- [ ] Een mislukte healthcheck, migratie, test, signingcheck of
  compatibiliteitscheck publicatie automatisch tegenhoudt.
- [ ] Rollback of hotfix in staging geoefend is voordat 100% productie-uitrol
  wordt toegestaan.

## Voorgestelde levervolgorde

Versienummers zijn richtinggevend en worden pas bij uitvoering definitief.

| Mijlpaal | Inhoud | Voornaamste eigenaar | Releasepoort |
| --- | --- | --- | --- |
| M0 | GitHub-secrets, groene AAB-workflow en bewijsartifact | Jij + Codex | Eerstvolgende technische release |
| M1 | Monitoring, redaction, healthchecks en incidentrunbook | Jij + Codex | Externe/bredere test |
| M2 | Stagingproject, volledige E2E-flow en eerste 100/1.000-user loadtest | Jij + Codex | Brede publieke beta |
| M3 | Expliciete multi-device conflicten en geteste restore | Codex, met jouw beleid | Brede publieke beta |
| M4 | Servereconomie in delen 4A–4D en migratie bestaande saves | Codex, met jouw productbesluiten | Eerlijke publieke economie |
| M5 | Uitgestelde Google Play Billing en receiptvalidatie via de voorbereide providergrens | Jij + Codex | Alleen vlak voordat echte verkoop gewenst is |
| M6 | Support/privacy-retentie, capaciteitsbewijs en staged rollout | Jij + Codex | Openbare productie |

M0 en de voorbereidingen voor M1 kunnen tegelijk worden gedaan. M2 volgt zodra
de externe projecten beschikbaar zijn. M3 kan functioneel worden voorbereid
tijdens M2. M4 hoort pas definitief gebouwd te worden nadat B1 en B2 vaststaan.
M5 blijft volledig los en uitgeschakeld totdat M4 bewezen klaar is én jij
besluit dat verkoop daadwerkelijk op korte termijn nodig is. De uitbreidingspunten
ervoor worden wel al in M4 getest.

## Algemene definition of done

Een taak of mijlpaal is pas gereed wanneer:

- [x] implementatie en relevante migraties zijn gereviewd voor v0.05.01;
- [x] analyzer en alle bestaande plus nieuwe tests slagen voor de huidige
  lokale bouwtranche (349/349 op 31-08-2026);
- [x] negatieve, timeout-, retry- en replaypaden zijn getest voor de huidige
  online clientgrens; toekomstige server-economiecommando's krijgen opnieuw
  dezelfde verplichte scenario's;
- [x] compacte UI en reduced motion zijn op exact 360×640 dp gecontroleerd;
  grotere tekst blijft door de bestaande regressietests afgedekt;
- [x] geen secrets of onnodige persoonsgegevens staan in code, logs of
  releaseartifacts;
- [x] migratie 32, begrenzing, dry-run en compatibiliteit met v0.05.00 zijn op
  staging en productie bewezen;
- [x] documentatie, runbook en beslissingen zijn voor v0.05.01 bijgewerkt;
- [x] verplichte productiepreflight slaagt op 32/32 migraties, 0 lintfouten,
  Auth 200/200 en applicatiehealth 200;
- [x] jij hebt v0.05.01 en de bijbehorende serverstap expliciet toegestaan.

## Eerstvolgende concrete acties

### Nu actief, in veilige volgorde

1. **Firebase is ingericht en bewezen.** Beide gratis projecten, Crashlytics,
   Performance en gesloten-app push zijn gecontroleerd. Analytics blijft uit.
   Verzamel nu een representatieve latency-/foutbaseline; privacy- en
   storeverklaringen blijven apart open. Zie `FIREBASE_MONITORING_SETUP.md`.
2. **Codex — servereconomie:** de gedeelde commandoregels, duurzame
   intent-/snapshotopslag en herstelgrens zijn gebouwd. De gewone winkel en
   kistopening zijn in de geïsoleerde staging-app met echte Auth/Edge/Postgres
   bewezen (`34281388567`). Ei-/draaklevensloop, uitrusting en Altar zijn inmiddels
   ook bewezen (`34286596835`), net als gewone Adventures/Wayfinder (`34289398487`)
   en woningacties (`34290527414`). Drakenvoorkeuren en de gecombineerde
   regressieproef zijn ook bewezen (`34291657311`, 679 tests). Rond resterende
   publieke gameplaymodellen en schermkoppelingen af.
   Daarna volgen gevalideerde trialbewijzen, serverdaggrenzen en sociale claims.
   Productie staat op schema 59 met legacy authority en uitgeschakelde economie.
3. **Codex — staging-load:** 100 gebruikers zijn gemeten met nul fouten;
   1000 gebruikers liepen tegen netwerk-time-outs aan. Cleanup is bevestigd.
   Isoleer de time-outfase en providerbelasting voordat de 100→1000-meting
   wordt herhaald; meet ook gevulde inventarissen, schrijflast en egress.
4. **Samen — activatievoorbereiding:** rond importreconciliatie, herstel,
   storings-/compensatieprocedures en begrijpelijke spelersteksten af voordat
   spelers worden omgezet. Behoud de bestaande prijzen en voortgang.
5. **Rick — operationele keuzes:** leg supportadres, verantwoordelijken,
   reactietijden en retentietermijnen vast; gebruik een echte privacyarme
   correlation ID voor de volledige supportoefening. Er ontbreekt geen
   Firebase-project of aanmeldstap meer.
6. **Codex — appgrootte:** vervolg de gratis beeldpilot; vervang geen volledige
   assetcategorie voordat de afgesproken visuele beoordeling is afgerond.
7. **Samen — acceptatie:** beoordeel de meetresultaten, conflicttekst,
   capaciteit, alarmdrempels en rollout-/rollbackbevoegdheid. Betaalde billing
   blijft uitgesteld en maakt geen deel uit van dit gratis traject.

### Reeds afgeronde actiehistorie

1. **Deels afgerond door jou:** B1, B2, B5 en de back-up/RPO/RTO-keuzes onder B6
   zijn bevestigd; voor B4 staat de toekomstige prijsladder vast maar activering
   blijft uitgesteld. B3, de resterende privacy-/retentiekeuzes en B7 worden vóór
   hun afhankelijke productiepoort beslist.
2. **Afgerond door jou:** Android Studio is gesloten; Codex heeft daarna de
   volledige Flutter-analyzer en alle 252 tests succesvol uitgevoerd.
3. **Afgerond door jou:** de zes repositorysecrets voor signing en productie-
   Supabase en de negen afgeschermde stagingsecrets zijn toegevoegd.
4. **Afgerond door Codex:** M0 is met een volledig groene handmatige AAB-
   workflow bewezen, zonder release, tag of productiewijziging.
5. **Afgerond door jou:** een afzonderlijk gratis Supabase-stagingproject en de
   GitHub Environment `staging` zijn ingericht.
6. **Afgerond samen:** signup, handmatige bevestiging van twee accounts, eerste
   login, accountbootstrap, vijfdelige cloudhistorie, oudere restore, bewuste
   lokale vervanging, stale-conflicten, Friends, trade en Group Adventure van
   create tot completion/reward/replay zijn echt op staging bewezen. De
   begrensde staging-only tijdregeling kan uitsluitend de zojuist aangemaakte
   fixture versnellen en weigert de vaste productiereferentie hard.
7. **Samen:** beoordeel de meetresultaten en leg pas daarna grenzen voor
   capaciteit, alerts en publieke uitrol vast.
8. **Afgerond door Codex:** v0.04.08 is met groene staging- en productie-gates
   gepubliceerd; APK en AAB hebben de vaste release-identiteit en productie
   doorstond na migratie opnieuw lint-, parity- en Auth-controles.
9. **Afgerond door Codex op staging en productie:** M3 bewaart de huidige plus vier vorige
   cloudrevisies gedurende maximaal dertig dagen, toont metadata, ondersteunt
   een expliciete oudere restore en bewaart de vorige cloudkopie bij bewuste
   vervanging. Migraties 21–23 zijn na afzonderlijke expliciete toestemming en
   een exacte 20→23-dry-run naar productie gebracht.
10. **Afgerond en bewezen door Codex:** automatische cloudback-up maximaal
    iedere vijftien minuten, een directe veilige flush bij achtergrond, de
    wekelijkse staging-restorecontrole en de uurlijkse productie-healthalert.
11. **Nog door jou voor volledige Firebase-monitoring:** maak het Spark-project,
    registreer `nl.dragonhaven.app`, laat Analytics uit en zet de gedownloade
    Android-config volgens `FIREBASE_MONITORING_SETUP.md` in de werkmap.
12. **Afgerond door Codex:** v0.04.10 is met 289/289 tests, een groene volledige
    staging-E2E, twee begrensde productiemigraties en dubbele releasegate
    gepubliceerd. Productie staat op 26/26 en de ondertekende APK/AAB gebruiken
    nog steeds de vaste release-identiteit.
13. **Afgerond door Codex:** v0.04.11 is met 298/298 tests, een groene volledige
    staging-E2E, de exact begrensde productiemigratie 26→27, een onafhankelijke
    productiepreflight en dubbele releasegate gepubliceerd. Productie staat op
    27/27; de APK/AAB behouden package `nl.dragonhaven.app` en het vaste
    releasecertificaat. De post-release healthcheck is eveneens groen.
14. **Afgerond door Codex:** v0.04.12 is met 301/301 tests, een lokale en twee
    CI-productiepreflights, compacte/reduced-motion emulatorcontrole en een
    dubbele releasegate gepubliceerd. De online refresh-storm en de
    batch-kistreveal zijn gestabiliseerd en afgeronde Adventures tonen hun
    rewards vooraf. Er waren geen databasemigraties nodig; productie blijft op
    27/27 en de post-release healthcheck is groen.
15. **Afgerond door Codex:** v0.04.13 is met 302/302 tests, een lokale
    productiepreflight, een onafhankelijke productiegate en Android-regressie-
    controles uitgebracht. De app vraagt notificatierechten niet langer
    herhaald of tijdens iedere koude start aan nadat Android ze heeft geweigerd;
    de notificatiepagina toont dan een compacte route naar de systeeminstellingen.
    Dit is op het gemelde fysieke toestel en op een Android-emulator met herhaalde
    koude starts bewezen. Er waren geen database- of servermigraties nodig;
    productie blijft op 27/27 en beide releasegates plus de post-release
    healthcheck zijn groen.
16. **Afgerond door Codex:** v0.04.14 is met 319/319 tests, een volledige
    sociale staging-E2E, de exact begrensde productiemigratie 27→28, een
    onafhankelijke productiepreflight en twee releasegates gepubliceerd.
    Kamerordening, Friend Adventure-uitleg, de 7-daagse Trial-streak, Keeper
    Journal, Dragon Academy en de payment-ready Supporter Pack/Vanity-laag zijn
    uitgerold. Productie staat op 28/28; live aankoop blijft bewust geblokkeerd
    tot fase 4 en server-side Google Play-verificatie gereed zijn. De
    post-release healthcheck is groen.
17. **Afgerond door Codex:** v0.04.15 is met 329/329 tests, een lokale
    productiepreflight en twee onafhankelijke productie-/signinggates
    gepubliceerd. Dragon Academy gebruikt nu tien visueel unieke lessen,
    leerling- en mentorselectie, drie officiële pogingen per les, rapportstatus,
    ranking, beloningen en Dropout/Valedictorian-achievements. Bestaande
    schoolvoortgang migreert via saveschema 47; er was geen databasemigratie
    nodig en productie blijft op 28/28. Compacte breedte en reduced motion zijn
    op de emulator gecontroleerd; de post-release healthcheck is groen.
18. **Afgerond door Codex:** v0.04.16 is met 339/339 tests, volledige staging,
    productiemigratie 29, een onafhankelijke productiepreflight en twee
    signinggates gepubliceerd. De release bevat de Dragon Academy-,
    foregroundmuziek-, blijvende weergave-, badge/Vanity-, Supporter-,
    Music Chest-, Packs-, Friends-refresh- en verzoekbadgeverbeteringen.
    Migratie 29 houdt oudere profiel-RPC's beschikbaar; productie staat op
    29/29 en de post-release healthcheck is groen.
19. **Afgerond door Codex:** v0.05.00 is met 347/347 tests, de uitgebreide
    Friend Messages-/Conclave-staging-E2E, de exact begrensde productiemigratie
    29→31, een onafhankelijke productiepreflight en twee signinggates
    gepubliceerd. Supporter-furniture en -portrait zijn gecorrigeerd en Android
    plant tijdkritische meldingen exact en herstelt ze na herstart, app-update en
    klok-/tijdzonewijzigingen. De APK en Play-ready AAB gebruiken versionCode
    10050 en het vaste releasecertificaat. Compacte breedte en reduced motion
    zijn op de emulator gecontroleerd; productie staat op 31/31 en de
    post-release healthcheck is groen.
20. **Afgerond door Codex:** v0.05.01 is met 349/349 tests, de reeds bewezen
    applicatiehealth-stagingflow, de exact begrensde productiemigratie 31→32,
    een onafhankelijke productiepreflight en de volledige tag-/signinggate
    gepubliceerd. Friends en Conclave hebben een compactere, duidelijkere UI;
    achievementshares tonen echte inhoud en de tutorial bestaat uit 17 actuele,
    volledig vertaalde stappen. APK en Play-ready AAB gebruiken versionCode
    10051 en het vaste certificaat. Exacte 360×640-dp/reduced-motion controle,
    remote APK-digest, beide downloadroutes en post-release Auth plus
    applicatiehealth zijn groen. Productie staat op 32/32.
21. **Afgerond door Codex:** v0.05.02 is met 375/375 tests, een exact begrensde
    productiemigratie 32→33, onafhankelijke 33/33-preflight en volledige
    tag-/signinggate gepubliceerd. De release bevat de Special Event-, Vanity-,
    Frostfable-, Academy-, Golden Hour-, Conclave-scroll- en
    privéberichtverbeteringen. APK en Play-ready AAB gebruiken versionCode 10052
    en het vaste certificaat. Exacte 360×640-dp/reduced-motion controle, remote
    APK-digest, beide downloadroutes en post-release Auth plus applicatiehealth
    zijn groen. Productie staat op 33/33.
22. **Afgerond door Codex:** v0.05.03 is met 402/402 tests, volledige staging-
    E2E, een exact begrensde productiemigratie 33→36 en de volledige tag-/
    signinggate gepubliceerd. Dragon chat-emotes en gescope Trial-ranglijsten
    zijn serverveilig actief; migratie 36 herstelde voorwaarts de enige door
    staging gevonden lintambiguïteit. APK en Play-ready AAB gebruiken
    versionCode 10053 en het vaste certificaat. Emulatorcontrole, remote
    APK-digest, beide downloadroutes en post-release Auth plus applicatiehealth
    zijn groen. Productie staat op 36/36.

## Besluitenlog

| Datum | ID | Besluit | Reden | Gevolg voor plan |
| --- | --- | --- | --- | --- |
| 28-08-2026 | B1 | Lokale weergave en gameplay blijven offline bruikbaar; toekomstige waardevolle online claims en mutaties worden server-authoritative | Eerlijkheid combineren met offline speelbaarheid | M4 mag deze grens als uitgangspunt gebruiken |
| 28-08-2026 | B2 | Bestaande saves krijgen één gelogde import met plausibiliteitslimieten en daarna server-lock; bestaande voortgang wordt nooit stil verwijderd | Veilige overgang zonder trouwe spelers voortgang af te nemen | Importprotocol en compatibiliteitstests mogen worden gebouwd |
| 28-08-2026 | B6-back-up | Per account de laatste vijf cloudrevisies maximaal dertig dagen bewaren | Voldoende herstelruimte met beperkte gratis opslag en privacy-impact | Back-uphistorie, opschoning en herstelkeuze mogen worden gebouwd |
| 28-08-2026 | M2-testtijd | Een hard staging-only tijdregeling mag Group Adventure completion versnellen | Volledige meerdaagse flow veilig en reproduceerbaar testen zonder productiepad | Completion/reward/replay en cleanup zijn volledig bewezen |
| 28-08-2026 | Release 0.04.08 | Migraties 21–23 en de nieuwe release zijn expliciet toegestaan | Auditverbeteringen gecontroleerd naar productie brengen | Productie staat op 23/23 en v0.04.08 is openbaar |
| 28-08-2026 | B5-monitoring | Firebase Spark met Crashlytics/Performance, Analytics uit; Rick ontvangt de eerste alerts; afgesproken providerretentie en 7/30 dagen voor support-/incidentbewijs | Gratis en privacyarm beginnen, later makkelijk uitbreidbaar | Healthalert mag worden geautomatiseerd; Firebase-SDK volgt zodra Rick het project/appconfig heeft gemaakt |
| 28-08-2026 | B6-automatische back-up | Betekenisvolle voortgang maximaal iedere 15 minuten automatisch back-uppen en openstaande voortgang direct veilig flushen bij achtergrond; RPO 15 minuten online, self-service RTO 15 minuten, supportdoel 4 uur; wekelijkse stagingtest en maandelijkse controle door Rick | Voortgang beschermen zonder gameplay of free tier onnodig te belasten | Automatische trigger en wekelijkse restoreworkflow mogen worden gebouwd |
| 28-08-2026 | Release 0.04.09 | Migratie 24 en een afzonderlijke nieuwe apprelease zijn expliciet toegestaan | Expertisegrenzen en aanvullende fixes client/server-consistent uitrollen | Productie staat op 24/24 en v0.04.09 is openbaar na groene staging-, migratie- en dubbele releasegates |
| 28-08-2026 | B4-prijscontract | Zowel de zes coinpacks als de zes gempacks gebruiken later de europrijsladder €1, €2, €5, €10, €20 en €30 | Play-producten vooraf eenduidig voorbereiden zonder betalingen vroeg te activeren | Interne catalogus bewaart de basisprijzen; de live UI moet later altijd Google Plays gelokaliseerde prijs tonen |
| 29-08-2026 | Release 0.04.10 | Broncode, migraties 25–26, staging, productie en de nieuwe apprelease zijn expliciet toegestaan | Special Events, serverondersteuning en de nieuwste spelcorrecties als één gecontroleerde versie uitrollen | Productie staat op 26/26 en v0.04.10 is openbaar na groene staging-, migratie- en dubbele releasegates |
| 30-08-2026 | Release 0.04.11 | Broncode, migratie 27, staging, productie en de nieuwe apprelease zijn expliciet toegestaan | Sinisterra/Sinister Eggs, incubatie tot op de seconde en batchgewijs kisten openen gecontroleerd uitrollen | Productie staat op 27/27 en v0.04.11 is openbaar na groene staging-, migratie-, productie-, tag- en healthgates |
| 30-08-2026 | Release 0.04.12 | Broncode en de nieuwe apprelease zijn expliciet toegestaan; deze tranche bevat geen databasemigratie | De gemelde online refresh-storm, crashgevoelige 10×-kistreveal en onduidelijke Adventure-rewards gecontroleerd herstellen | Productie blijft op 27/27 en v0.04.12 is openbaar na twee groene productie-/releasegates en een groene healthcheck |
| 30-08-2026 | Release 0.04.13 | Broncode en de nieuwe apprelease zijn expliciet toegestaan; deze tranche bevat geen databasemigratie | Voorkomen dat een eerder geweigerde Android-notificatieprompt tijdens koude starts de app naar de achtergrond stuurt en als terugkerende storing aanvoelt | Productie blijft op 27/27 en v0.04.13 is openbaar na fysieke toestelcontrole, emulatorregressie, twee groene releasegates en een groene post-release healthcheck |
| 30-08-2026 | Release 0.04.14 | Broncode, staging, productiemigratie 28 en de nieuwe apprelease zijn expliciet toegestaan | De featuretranche met progression, Dragon Academy en Supporter Vanity gecontroleerd en servercompatibel uitrollen | Productie staat op 28/28 en v0.04.14 is openbaar na groene staging-, migratie-, productie-, tag- en healthgates; echte aankopen blijven uitgeschakeld |
| 31-08-2026 | Release 0.04.15 | Broncode en de nieuwe apprelease zijn expliciet toegestaan; deze tranche bevat geen databasemigratie | De uitgebreide Dragon Academy-opleiding, rapportstatussen, nieuwe sprites en Supporter-/Trial-presentatie gecontroleerd uitrollen | Productie blijft op 28/28 en v0.04.15 is openbaar na lokale preflight, 329 tests, compacte/reduced-motion controle, twee groene releasegates en een groene healthcheck; echte aankopen blijven uitgeschakeld |
| 31-08-2026 | Release 0.04.16 | Broncode, staging, productiemigratie 29 en de nieuwe apprelease zijn expliciet toegestaan | De Dragon Academy-/Vanity-/Supporter-verbeteringen, robuuste Friends-refresh en verzoekbadge gecontroleerd en achterwaarts compatibel uitrollen | Productie staat op 29/29 en v0.04.16 is openbaar na groene lokale checks, staging-, migratie-, productie-, tag- en healthgates. Echte aankopen blijven uitgeschakeld |
| 31-08-2026 | Release 0.05.00 | Broncode, staging, productiemigraties 30–31 en de nieuwe apprelease zijn expliciet toegestaan | Friend Messages en Conclaves plus de notificatie- en Supporter-correcties als serverveilige hoofdversie uitrollen; migratie 31 is de noodzakelijke idempotente lintcorrectie na de eerste stagingpoging | Productie staat op 31/31 en v0.05.00 is openbaar na groene 347-testgate, uitgebreide twee-account staging-E2E, begrensde migratie 29→31, dubbele releasegate, emulatorcontrole en post-release healthcheck; echte aankopen blijven uitgeschakeld |
| 31-08-2026 | Release 0.05.01 | Broncode, productiemigratie 32 en de nieuwe apprelease zijn expliciet toegestaan | De vernieuwde Friends-/Conclave-UI, actuele tutorial en privacyveilige applicatiehealth als één gecontroleerde patch uitrollen | Productie staat op 32/32 en v0.05.01 is openbaar na 349 tests, voorafgaande staging-E2E, begrensde migratie 31→32, onafhankelijke preflight, 360×640-dp/reduced-motion controle, signing-/AAB-gate, assetdigestcontrole en post-release health; echte aankopen blijven uitgeschakeld |
| 01-09-2026 | Release 0.05.02 | Broncode, productiemigratie 33 en de nieuwe apprelease zijn expliciet toegestaan | De sinds v0.05.01 gebouwde gameplay-, sprite-, vanity-, Academy-, Golden Hour-, Conclave- en berichtcorrecties gecontroleerd uitrollen en de al op staging bewezen support/privacygrens activeren | Productie staat op 33/33 en v0.05.02 is openbaar na 375 tests, begrensde migratie 32→33, onafhankelijke preflight, 360×640-dp/reduced-motion controle, signing-/AAB-gate, assetdigestcontrole en post-release health; echte aankopen blijven uitgeschakeld |
| 02-09-2026 | Release 0.05.03 | Broncode, staging, productiemigraties 34–36 en de nieuwe apprelease zijn expliciet toegestaan | De featuretranche met chat-emotes, Trial-ranglijsten en de nieuwste UI-/spritecorrecties als één gecontroleerde, servercompatibele versie uitrollen | Productie staat op 36/36 en v0.05.03 is openbaar na voorwaartse lintcorrectie, volledige staging-E2E, 402 tests, begrensde migratie 33→36, emulator-, signing-/AAB-, assetdigest- en post-release-healthgates; echte aankopen blijven uitgeschakeld |
| Nog te bepalen | B3, B4-activering en B7 | Nog niet bevestigd | Beslissen vlak vóór de afhankelijke fase | Alleen de nog afhankelijke delen van M4–M6 wachten |

## Voortgangslog

| Datum | Mijlpaal/taak | Uitgevoerd door | Bewijs of link | Resultaat/vervolg |
| --- | --- | --- | --- | --- |
| 28-08-2026 | Uitgangsaudit v0.04.06 | Codex | `DRAGONHAVEN_AUDIT_2026-08-28.md` | Basis groen; resterende grenzen in dit plan verwerkt |
| 28-08-2026 | M0 workflowhardening | Codex | `.github/workflows/release.yml` | Vroege secretcheck, pubspec-versionCode, AAB-hash/certificaat en bewijsrapport gebouwd |
| 28-08-2026 | M1 gratis diagnostiekbasis | Codex | `lib/services/diagnostic_reporter.dart`, `INCIDENT_RUNBOOK.md` | Supportcodes, veilige export, redactiontests en handmatige healthworkflow gebouwd |
| 28-08-2026 | Productiepreflight na healthrefactor | Codex | `tool/release_server_preflight.ps1` | 20/20 migraties, 0 lintfouten, Auth 200/200; eerste health 24,5 s, clienttimeout daarom 75 s |
| 28-08-2026 | M2 stagingafscheiding | Codex | `.github/workflows/staging.yml`, `lib/config/online_config.dart` | Production/staging/local veilig gescheiden |
| 28-08-2026 | M3 conservatieve conflictbeveiliging | Codex | `OnlineAccountProvider`, `StorageService`, `AccountScreen` | Stil cloudoverschrijven geblokkeerd; restore/lokaal-doorgaan gebouwd, force-overwrite wacht op retentie- en historiebeleid |
| 28-08-2026 | Uitgestelde payment-ready grens | Codex | `lib/services/purchase_provider.dart` | Twaalf interne product-ID's en server-verified contract; geen Billing-SDK, liveproducten of kosten geactiveerd |
| 28-08-2026 | Volledige lokale kwaliteitscontrole | Codex | `flutter analyze --no-pub`, `flutter test --no-pub` | Analyzer zonder issues; 252/252 tests geslaagd nadat Android Studio was gesloten |
| 28-08-2026 | Lokalisatie support- en cloudteksten | Codex | `lib/l10n/release_phrase_translations.dart`, `test/localization_completeness_test.dart` | Twaalf nieuwe vaste teksten in alle zes aanvullende talen toegevoegd; 10/10 lokalisatiecontroles geslaagd |
| 28-08-2026 | M2 eerste echte stagingverificatie | Jij + Codex | [GitHub Actions-run 33176572637](https://github.com/Rakky88/DragonHaven/actions/runs/33176572637) | Public-only basis: safetychecks, 20 migraties, lint, preflight, analyzer, 252 tests en geïsoleerde APK groen |
| 28-08-2026 | M0 Play Store-readinessbewijs | Jij + Codex | [GitHub Actions-run 33177281257](https://github.com/Rakky88/DragonHaven/actions/runs/33177281257) | Ondertekende AAB, productiepreflight, analyzer en 252 tests groen; bewijsartifact gemaakt, geen release of tag gepubliceerd |
| 28-08-2026 | M2 bevestigde account- en back-up-E2E | Jij + Codex | [GitHub Actions-run 33180648232](https://github.com/Rakky88/DragonHaven/actions/runs/33180648232) | Login, bevestigde e-mail, bootstrap, profiel, back-up/restore, stale-revisionweigering, logout, analyzer, 252 tests en staging-APK groen |
| 28-08-2026 | M2 tweepersoons sociale staging-E2E | Jij + Codex | [GitHub Actions-run 33182884493](https://github.com/Rakky88/DragonHaven/actions/runs/33182884493) | Friends, atomaire chest-trade en Group Adventure create/list/join/leave met veilige cleanup groen; analyzer, 252 tests, staging-APK en bewijsartifact groen; completion/rewardpad blijft open |
| 28-08-2026 | Openbare release v0.04.07 | Codex | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.07), [gate 33185616650](https://github.com/Rakky88/DragonHaven/actions/runs/33185616650) | Ondertekende APK gepubliceerd; productiepreflight, analyzer, 252 tests, AAB-signing en hashbewijs groen |
| 28-08-2026 | Negatieve online herstelpaden | Codex | `test/online_social_test.dart` | Verlopen sessie, timeout plus reconnect, dubbele tap, half afgemaakte Group Reward en trade-replay na save/herstart getest; volledige set 256/256 groen |
| 28-08-2026 | Veilige bestaande-save-importbasis | Codex | `202608280021_audited_legacy_inventory_import.sql` | Versie, limieten, privacyarm rapport, SHA-256 en private 30-daagse herstelkopie gebouwd; gecontroleerde rollbackuitvoering volgt |
| 28-08-2026 | Importmigratie op staging | Codex | [Stagingrun 33188269327](https://github.com/Rakky88/DragonHaven/actions/runs/33188269327) | Migratie 21 toegepast; 21/21 parity, schema-lint/preflight, analyzer, 256 tests en staging-APK groen |
| 28-08-2026 | Importstatus/rapport-E2E | Codex | [Stagingrun 33189927346](https://github.com/Rakky88/DragonHaven/actions/runs/33189927346) | Bevestigd account bewijst coherentie: niet geïmporteerd geeft nul auditrecords; geïmporteerd vereist exact één geldig versie-0/1-rapport |
| 28-08-2026 | Gratis dashboardspecificatie | Codex | `OBSERVABILITY_BASELINE.md` | Privacyarme panelen, meetvelden, zeven-dagenbaseline, gratis startbronnen en later upgradepad vastgelegd; echte alerts wachten op eigenaar/projectkeuze |
| 28-08-2026 | M3 herstelbare cloudhistorie | Codex | [Stagingrun 33193296552](https://github.com/Rakky88/DragonHaven/actions/runs/33193296552), migraties 22 en 23 | 23/23 migraties, database-lint/preflight, twee echte revisies, oude-save-readback, stale-writeweigering, analyzer, 259 tests, staging-APK en bewijsartifact groen; productie ongewijzigd op 20 migraties |
| 28-08-2026 | CI-runtimeonderhoud | Codex | [Stagingrun 33194122823](https://github.com/Rakky88/DragonHaven/actions/runs/33194122823), commit `2a52e9af804f8415a6546d1c5c128b2ab4fe912c` | Supabase Setup CLI v3 en Upload Artifact v6 bewezen; 23/23 stagingmigraties, lint/preflight, analyzer, 259 tests, staging-APK en artifact groen |
| 28-08-2026 | Publieke productie-healthcheck | Codex | [Healthrun 33194121092](https://github.com/Rakky88/DragonHaven/actions/runs/33194121092) | Read-only Auth-healthcheck en het driedaagse privacyarme bewijsartifact groen; veilige applicatie-RPC, planning en alerts blijven onder fase 1 open |
| 28-08-2026 | Volledige Group Adventure staging-E2E | Codex | [Stagingrun 33196707499](https://github.com/Rakky88/DragonHaven/actions/runs/33196707499) | Create/join/start/completion, exact één reward per deelnemer, duplicate acknowledgement, claim-replay en volledige cleanup groen via een hard staging-only tijdregeling |
| 28-08-2026 | v0.04.08 releasecandidate op staging | Codex | [Stagingrun 33197572353](https://github.com/Rakky88/DragonHaven/actions/runs/33197572353) | 23/23 migraties, volledige sociale E2E, analyzer, 261 tests en geïsoleerde staging-APK groen |
| 28-08-2026 | Productiemigraties 21–23 | Codex, na jouw toestemming | [Migratierun 33198153589](https://github.com/Rakky88/DragonHaven/actions/runs/33198153589) | Exacte beginstand 20, dry-run, database-lint en Auth groen; productie gecontroleerd naar 23/23 gemigreerd en opnieuw geverifieerd |
| 28-08-2026 | Openbare release v0.04.08 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.08), [productiegate 33198225157](https://github.com/Rakky88/DragonHaven/actions/runs/33198225157), [taggate 33198930542](https://github.com/Rakky88/DragonHaven/actions/runs/33198930542) | Ondertekende APK van 327.993.256 bytes gepubliceerd; SHA-256 `3880354b1dafebabcc39c824eac8899bfc4a339ad8b5b0b712edb7e971cb2826`; beide productiepreflights, 261 tests en Play-ready AAB groen |
| 28-08-2026 | B5/B6 implementatietranche voor v0.04.09 | Codex | `automatic_cloud_backup.dart`, `weekly-staging-restore.yml`, `health-check.yml`, `FIREBASE_MONITORING_SETUP.md` | Automatische 15-minutenback-up plus achtergrondflush, wekelijkse echte restore en uurlijkse productiecheck met één toegewezen SEV-1-issue gebouwd; Firebase-client wacht uitsluitend op Rick's projectconfig |
| 28-08-2026 | v0.04.09 releasecandidate op staging | Codex | [Stagingrun 33204337160](https://github.com/Rakky88/DragonHaven/actions/runs/33204337160) | Migratie 24, database-lint/preflight, volledige sociale en Group Adventure-E2E, analyzer, 270 tests, geïsoleerde staging-APK en bewijsartifact groen |
| 28-08-2026 | Productiemigratie 24 | Codex, na jouw toestemming | [Migratierun 33204827275](https://github.com/Rakky88/DragonHaven/actions/runs/33204827275) | Exacte beginstand 23, dry-run en database-lint groen; alleen migratie 24 toegepast en daarna 24/24 parity plus Auth opnieuw groen |
| 28-08-2026 | Eerste monitoring- en restorebewijzen | Codex | [Healthrun 33205759992](https://github.com/Rakky88/DragonHaven/actions/runs/33205759992), [restorerun 33205758376](https://github.com/Rakky88/DragonHaven/actions/runs/33205758376) | Productiehealth HTTP-groen; actuele en historische staging-cloudsave succesvol hersteld; beide privacyarme bewijsartifacts dertig dagen bewaard |
| 28-08-2026 | Openbare release v0.04.09 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.09), [productiegate 33204987488](https://github.com/Rakky88/DragonHaven/actions/runs/33204987488), [taggate 33205588983](https://github.com/Rakky88/DragonHaven/actions/runs/33205588983) | Ondertekende APK van 328.058.796 bytes gepubliceerd; SHA-256 `4b03399bb31545a80af04c3919d4a8e3795bb3d14a627f4cf11903dc704be31a`; beide productiepreflights, 270 tests en Play-ready AAB groen |
| 28-08-2026 | Correcties voor v0.04.10 | Codex | `pet.dart`, `social.dart`, migratie 25 en begrensde workflow 24→25 | Infernal Mastery gebruikt 400 voor Might, Arcana en Spirit; Friends telt ontdekte normale vormen in plaats van families; later via de v0.04.10-tranche bewezen en uitgerold |
| 28-08-2026 | Toekomstig Play-prijscontract | Jij + Codex | `purchase_provider.dart`, `purchase_provider_test.dart` | Voor coins en gems is €1/€2/€5/€10/€20/€30 per pakketpositie vastgelegd; provider blijft bewust uitgeschakeld tot fase 4 en het activeringsbesluit zijn afgerond |
| 29-08-2026 | Special Adventure-framework en Cluckatrice-event | Codex | `special_adventure_test.dart`, migratie 26, [stagingrun 33244546317](https://github.com/Rakky88/DragonHaven/actions/runs/33244546317) | Datagedreven terugkerende events, Special Chest/Egg, Cluckatrice, achievement, eventmelding, 21-uurs incubatie en serverondersteuning bewezen; volledige sociale en Group Adventure-E2E, analyzer en 289 tests groen |
| 29-08-2026 | Automatisch uitkomen en veilige presentaties | Codex | `automatic_hatch_coordinator_test.dart`, `hatch_presentation_test.dart`, commit `581e9bd19c4e29b59b44f413d27a953a7d4bd157` | Eieren komen bij verstreken tijd automatisch uit; Tower toont de resterende tijd; hatch/evolutie/achievement wachten tot een actieve Trial inclusief rewards is afgerond; Cluckatrice-transparantie is opnieuw begrensd getest |
| 29-08-2026 | Productiemigraties 25–26 | Codex, na jouw toestemming | [migratie 25](https://github.com/Rakky88/DragonHaven/actions/runs/33244862612), [migratie 26](https://github.com/Rakky88/DragonHaven/actions/runs/33244914831) | Iedere workflow controleerde de exacte beginstand, dry-run, database-lint, Auth en eindpariteit; productie staat gecontroleerd op 26/26 |
| 29-08-2026 | Openbare release v0.04.10 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.10), [productiegate 33245012909](https://github.com/Rakky88/DragonHaven/actions/runs/33245012909), [taggate 33245410169](https://github.com/Rakky88/DragonHaven/actions/runs/33245410169) | Ondertekende APK van 335.020.376 bytes gepubliceerd; SHA-256 `2b821fd88daf1ee1143669f3b654019fd3b8fdf18889f9cbe678d98aa36e4497`; productiepreflights, 289 tests en Play-ready AAB groen |
| 29-08-2026 | Post-release productiehealth | Codex | [Healthrun 33245762747](https://github.com/Rakky88/DragonHaven/actions/runs/33245762747) | Publieke productie-endpoints direct na v0.04.10 opnieuw groen; bewijsartifact geüpload en er stond geen open storingsalert |
| 30-08-2026 | v0.04.11 releasecandidate op staging | Codex | [Stagingrun 33281827365](https://github.com/Rakky88/DragonHaven/actions/runs/33281827365) | Migratie 27, database-lint/preflight, volledige sociale en Group Adventure-E2E, analyzer, 298 tests, geïsoleerde staging-APK en bewijsartifact groen |
| 30-08-2026 | Productiemigratie 27 | Codex, na jouw toestemming | [Migratierun 33282124409](https://github.com/Rakky88/DragonHaven/actions/runs/33282124409) | Exacte beginstand 26, publieke healthcheck, database-lint en dry-run groen; alleen migratie 27 toegepast en daarna 27/27 parity plus Auth opnieuw groen |
| 30-08-2026 | Openbare release v0.04.11 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.11), [productiegate 33282204885](https://github.com/Rakky88/DragonHaven/actions/runs/33282204885), [taggate 33282583148](https://github.com/Rakky88/DragonHaven/actions/runs/33282583148) | Ondertekende APK van 339.929.596 bytes gepubliceerd; SHA-256 `2417cf18393220471c6f09ba59960bce875ed753f3276478c9fe9b56c8d18fd1`; beide productiepreflights, 298 tests en Play-ready AAB groen |
| 30-08-2026 | Post-release productiehealth | Codex | [Healthrun 33282909288](https://github.com/Rakky88/DragonHaven/actions/runs/33282909288) | Publieke productie-endpoints direct na v0.04.11 opnieuw groen; bewijsartifact geüpload en er staat geen open storingsalert |
| 30-08-2026 | Openbare release v0.04.12 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.12), [productiegate 33303254299](https://github.com/Rakky88/DragonHaven/actions/runs/33303254299), [taggate 33303625899](https://github.com/Rakky88/DragonHaven/actions/runs/33303625899) | Ondertekende APK van 339.962.388 bytes gepubliceerd; SHA-256 `5d93c58c32e072cd5655f1afbeb761b849048529e16a17cc83b3421a7b340155`; package `nl.dragonhaven.app`, versionCode 10045 en vast releasecertificaat bewezen; beide productiepreflights, 301 tests, compacte/reduced-motion UI-controle en Play-ready AAB groen |
| 30-08-2026 | Post-release productiehealth | Codex | [Healthrun 33303962771](https://github.com/Rakky88/DragonHaven/actions/runs/33303962771) | Publieke productie-endpoints direct na v0.04.12 opnieuw groen; bewijsartifact geüpload, productie blijft op 27/27 migraties en er staat geen open storingsalert |
| 30-08-2026 | Openbare release v0.04.13 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.13), [productiegate 33305564413](https://github.com/Rakky88/DragonHaven/actions/runs/33305564413), [taggate 33305906855](https://github.com/Rakky88/DragonHaven/actions/runs/33305906855) | Ondertekende APK van 339.962.464 bytes gepubliceerd; SHA-256 `ec98434a99feafa2780561b494847763e4278169b6c58b0d769af8c060edbff3`; package `nl.dragonhaven.app`, versionCode 10046 en vast releasecertificaat bewezen; productiepreflight, 302 tests en de nieuwe denied-permission-regressies zijn groen |
| 30-08-2026 | Post-release productiehealth v0.04.13 | Codex | [Healthrun 33306212649](https://github.com/Rakky88/DragonHaven/actions/runs/33306212649) | Publieke productie-endpoints direct na v0.04.13 opnieuw groen; bewijsartifact geüpload, productie blijft op 27/27 migraties en er staat geen open storingsalert |
| 30-08-2026 | Featuretranche voor v0.04.14 | Codex | `new_feature_batch_widget_test.dart`, `household_provider_test.dart`, `sprite_bounds_test.dart`, `online_social_test.dart`, migratie 28 | Kamerordening, Friend Adventure-uitleg, 7-daagse Trial-streak met reset naar nul na een gemiste dag, Keeper Journal, Dragon Academy, vaste Sinisterra-alignment en payment-ready Supporter Pack gebouwd. Het Supporter-portretframe is een selecteerbare Vanity-keuze en wordt compatibel naar vriendenprofielen gesynchroniseerd; de oude profiel-RPC blijft voor bestaande apps bestaan. Static analysis en 319/319 tests zijn groen; live aankoop blijft veilig geblokkeerd tot fase 4 en server-side Google Play-verificatie klaar zijn. |
| 30-08-2026 | v0.04.14 releasecandidate op staging | Codex | [Stagingrun 33329371768](https://github.com/Rakky88/DragonHaven/actions/runs/33329371768) | Migratie 28, volledige twee-account social flow, analyzer, 319 tests, geïsoleerde staging-APK en bewijsartifact groen |
| 30-08-2026 | Productiemigratie 28 en onafhankelijke preflight | Codex, na jouw toestemming | [Migratierun 33329749508](https://github.com/Rakky88/DragonHaven/actions/runs/33329749508), `tool/release_server_preflight.ps1` | Exacte beginstand 27 en dry-run groen; alleen migratie 28 toegepast. Daarna 28/28 parity, 0 database-lintfouten en Auth health/settings 200/200 op project `tnzathhutuwmohmjfrlo` bewezen |
| 30-08-2026 | Openbare release v0.04.14 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.14), [productiegate 33329828902](https://github.com/Rakky88/DragonHaven/actions/runs/33329828902), [taggate 33330282266](https://github.com/Rakky88/DragonHaven/actions/runs/33330282266) | Ondertekende APK van 345.934.831 bytes gepubliceerd; SHA-256 `f1f77ab4b40be9265e5cd650be888ad803eea161a6a7f0bf19803fcb3eeae49f`; package `nl.dragonhaven.app`, versionCode 10047 en vast releasecertificaat bewezen; beide productiepreflights, 319 tests en Play-ready AAB groen |
| 30-08-2026 | Post-release productiehealth v0.04.14 | Codex | [Healthrun 33330682921](https://github.com/Rakky88/DragonHaven/actions/runs/33330682921) | Publieke productie-endpoints direct na v0.04.14 opnieuw groen; bewijsartifact geüpload, productie staat op 28/28 migraties en er staat geen open storingsalert |
| 31-08-2026 | Dragon Academy-verdieping voor v0.04.15 | Codex | commit `0c38def1a999b8a9d05f59e5e302fc11965a7fd7`, `dragon_school.dart`, `dragon_school_screen.dart`, `household_provider_test.dart`, `new_feature_batch_widget_test.dart`, `sprite_bounds_test.dart` | Tien visueel unieke lessen met eigen achtergronden en speelstukken, leerlingen, teamlessen, mentoren, drie pogingen per les, blijvende scores/sterren, rapportstatussen, Academy Score en nieuwe achievements gebouwd; saveschema 47 bewaart bestaande academievoortgang veilig; analyzer en 329/329 tests groen |
| 31-08-2026 | Openbare release v0.04.15 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.15), [productiegate 33339570035](https://github.com/Rakky88/DragonHaven/actions/runs/33339570035), [taggate 33340087680](https://github.com/Rakky88/DragonHaven/actions/runs/33340087680) | Ondertekende APK van 355.843.461 bytes gepubliceerd; SHA-256 `9ab67c4164f69c9a4211491cb4afa2c66b7c19123ec6a87ee854fcef802c4180`; package `nl.dragonhaven.app`, versionCode 10048 en vast releasecertificaat bewezen; beide productiepreflights, 329 tests, compacte/reduced-motion UI-controle en Play-ready AAB groen; geen databasemigratie, productie blijft 28/28 |
| 31-08-2026 | Post-release productiehealth v0.04.15 | Codex | [Healthrun 33340431353](https://github.com/Rakky88/DragonHaven/actions/runs/33340431353) | Publieke productie-endpoints direct na v0.04.15 opnieuw groen; bewijsartifact geüpload, productie staat op 28/28 migraties en er staat geen open storingsalert |

| 31-08-2026 | v0.04.16 featuretranche | Codex | commit `89fee10510b0076c2f68adab730877e7ffd69695`, saveschema 48, migratie 29, `audio_service_test.dart`, `household_provider_test.dart`, `new_feature_batch_widget_test.dart`, `online_social_test.dart`, `widget_test.dart` | Dragon Academy-naamgeving en vervroegd afstuderen, gecentreerde Sigil Memory/Shadow Match, uitsluitend voorgrondmuziek, herstelde Trial-constellatie, blijvende My Dragons/Eggs-weergavevoorkeuren, uitbreidbare online badges, plaatsbare Supporter-furniture, een onderscheidende geopende Music Chest, een stabiele heropenbare Packs-pagina en een live rode teller voor inkomende verzoeken op de Friends-tab gebouwd. De Friends-refresh bewaart nu een geldige server-snapshot voordat niet-kritieke onderhoudstaken draaien; een onderhoudsfout kan daardoor niet langer het profiel en de vriendenlijst leegtrekken en krijgt een eigen privacyarme diagnose-operatie. De productiecheck voor Qnosick bewees een bereikbaar account, geldige snapshot en werkend notificatie-acknowledgement zonder gegevens te wijzigen. Analyzer en 339/339 tests zijn groen. |
| 31-08-2026 | v0.04.16 releasecandidate op staging | Codex | [Stagingrun 33376878533](https://github.com/Rakky88/DragonHaven/actions/runs/33376878533) | Migratie 29, databasepreflight, volledige twee-account social- en Group Adventure-E2E, analyzer, 339 tests, geïsoleerde staging-APK en bewijsartifact groen |
| 31-08-2026 | Productiemigratie 29 en onafhankelijke preflight | Codex, na jouw toestemming | [Migratierun 33377566011](https://github.com/Rakky88/DragonHaven/actions/runs/33377566011), `tool/release_server_preflight.ps1` | Exacte beginstand 28, publieke healthcheck, database-lint en dry-run groen; uitsluitend migratie 29 toegepast. Daarna 29/29 parity, 0 database-lintfouten en Auth health/settings 200/200 op project `tnzathhutuwmohmjfrlo` bewezen. Oudere profiel-RPC's blijven beschikbaar |
| 31-08-2026 | Openbare release v0.04.16 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.16), [productiegate 33377773908](https://github.com/Rakky88/DragonHaven/actions/runs/33377773908), [taggate 33378504659](https://github.com/Rakky88/DragonHaven/actions/runs/33378504659) | Ondertekende APK van 358.433.995 bytes gepubliceerd; SHA-256 `fe94f1d5b33cea84acfe045d6ee8c3269c53575162925e2e4ee89a54206388bf`; package `nl.dragonhaven.app`, versionCode 10049 en vast releasecertificaat bewezen; beide productiepreflights, 339 tests en Play-ready AAB groen; GitHubs versiegebonden en permanente latest-download wijzen naar hetzelfde asset |
| 31-08-2026 | Post-release productiehealth v0.04.16 | Codex | [Healthrun 33379163158](https://github.com/Rakky88/DragonHaven/actions/runs/33379163158) | Publieke productie-endpoints direct na v0.04.16 opnieuw groen; bewijsartifact geüpload, productie staat op 29/29 migraties en er staat geen open storingsalert |
| 31-08-2026 | Lokale Friend Messages- en Conclave-tranche | Codex | migraties `202608310030_friend_messages_and_conclaves.sql` en `202608310031_fix_conclave_function_ambiguity.sql`, `friend_messages_screen.dart`, `conclave_screen.dart`, 31 nieuwe sociale sprites, `social_phrase_translations.dart`, `online_social_test.dart`, `notification_service_test.dart`, `sprite_bounds_test.dart` en `dragonhaven_spec_test.dart` | Vriendenchats en Conclaves zijn lokaal in client en servercontract gebouwd. Alle nieuwe tabellen blijven via RLS en ingetrokken tabelrechten afgeschermd; tijdelijke chatdata heeft vijfminuten-Cron plus opportunistische cleanup; Aerie-progressie kan door maximaal twintig bijdragen per UTC-dag niet sneller dan 192 dagen naar fase 10. De eerste stagingpoging paste migratie 30 toe en stopte vóór E2E op twee lintambiguïteiten; migratie 31 herstelt die idempotent, terwijl productie onaangeraakt op 29/29 blijft. |
| 31-08-2026 | Lokale clientcorrecties na v0.04.16 | Codex | `house_screen.dart`, `profile_portrait_sprite.dart`, `notification_service.dart`, `notification_settings_screen.dart`, `MainActivity.kt`, `DragonHavenAlarmScheduler.kt` en regressietests | Geplaatste Supporter-furniture wordt uit de volledige catalogus gerenderd; het Founding Supporter Portrait gebruikt dezelfde schaal als andere portraits. De oude algemene vertraging van twee minuten en de extra Adventure-seconde zijn verwijderd: eieren, Adventures, volle Trials en Special Events worden op hun exacte spelgrens gepland. Android 12+ controleert expliciete alarmtoegang, biedt een Play-geschikte `SCHEDULE_EXACT_ALARM`-instellingenroute en plant lopende timers opnieuw bij een toestemmingswijziging, toestelherstart, app-update of klok-/tijdzonewijziging; reeds verlopen meldingen worden niet alsnog te laat getoond. Analyzer, 347/347 tests en Android-debugbuild zijn groen; versie 0.4.16, productie 29/29 en de openbare release zijn onaangeraakt. |
| 31-08-2026 | v0.05.00 lokale releasecandidate | Codex, na jouw toestemming | `release-notes-v0.05.00.md`, migraties 30–31, `production-migrate-31.yml`, uitgebreide `staging_social_e2e.ps1` en ondertekende APK | App- en zichtbare versie staan op v0.05.00 met versionCode 10050; analyzer en 347/347 tests zijn groen. De lokale productie-APK heeft package `nl.dragonhaven.app`, het vaste releasecertificaat en de juiste versie; staging, productie en publicatie volgen nog via de externe gates. |
| 31-08-2026 | v0.05.00 releasecandidate op staging | Codex | [Stagingrun 33396777406](https://github.com/Rakky88/DragonHaven/actions/runs/33396777406) | Na een veilig gestopte eerste lintpoging zijn migraties 30–31, database-lint/preflight, Friend Messages, Conclaves, Friends, trade, volledige Group Adventure completion/reward/replay, analyzer, 347 tests, geïsoleerde staging-APK en cleanup groen bewezen. Productie bleef tijdens de correctie onaangeraakt. |
| 31-08-2026 | Productiemigraties 30–31 en onafhankelijke preflight | Codex, na jouw toestemming | [Migratierun 33397552524](https://github.com/Rakky88/DragonHaven/actions/runs/33397552524), `tool/release_server_preflight.ps1` | Exacte beginstand 29, publieke healthcheck, database-lint en dry-run groen; uitsluitend migraties 30–31 toegepast. Daarna 31/31 parity, 0 database-lintfouten, Auth health/settings 200/200 en geconfigureerde e-mailauth op project `tnzathhutuwmohmjfrlo` bewezen. |
| 31-08-2026 | Openbare release v0.05.00 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.00), [productiegate 33397872901](https://github.com/Rakky88/DragonHaven/actions/runs/33397872901), [taggate 33398718801](https://github.com/Rakky88/DragonHaven/actions/runs/33398718801) | Exact commit `603648c7eb1224ea855b616b7c1729e7839c9da8` getagd. Ondertekende APK van 366.785.471 bytes gepubliceerd; SHA-256 `c0f431393f41c03b6c111e403d7ba465bbe1bbd6318345cf57610e7548c92592`; package `nl.dragonhaven.app`, versionCode 10050 en vast releasecertificaat `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942` bewezen. Beide productiepreflights, 347 tests, compacte/reduced-motion emulatorcontrole en Play-ready AAB zijn groen; versiegebonden en permanente latest-download geven HTTP 200 en hetzelfde GitHub-asset. |
| 31-08-2026 | Post-release productiehealth v0.05.00 | Codex | [Healthrun 33399531445](https://github.com/Rakky88/DragonHaven/actions/runs/33399531445) | Publieke productie-endpoints direct na v0.05.00 opnieuw groen; bewijsartifact geüpload, productie staat op 31/31 migraties en er is geen storingsalert geopend. |
| 31-08-2026 | M1 read-only applicatiehealth gebouwd en op staging bewezen | Codex | migratie `202608310032_public_application_health.sql`, `public_server_health_check.ps1`, `release_server_preflight.ps1`, `test_public_application_health.ps1`, `production-migrate-32.yml`, `dragonhaven_spec_test.dart` en [stagingrun 33402550922](https://github.com/Rakky88/DragonHaven/actions/runs/33402550922) | Een publieke `security invoker`-RPC zonder tabelreads retourneert uitsluitend vaste servicestatus, contractversie en servertijd. De monitor valideert HTTP-status, exact contract en maximaal vijf minuten klokafwijking; productiepreflight eist de check na migratie 32. Stagingmigratie/lint/preflight, positieve/negatieve parsertests, volledige sociale en Group Adventure-E2E, live productie-Auth 200/200, analyzer, 348/348 tests en staging-APK zijn groen. De latere migratierun `33414590573` activeerde dit veilig op productie; productie staat nu op 32/32. De toen nog open testalertdelivery is later aantoonbaar afgerond in run `33435265676`. |
| 31-08-2026 | v0.05.01 lokale releasecandidate | Codex, na jouw toestemming | commit `b4a49a932e824aedba5031aca5f21675cda762a1`, `release-notes-v0.05.01.md`, Friends/Conclave/tutorial-regressies en ondertekende APK | Analyzer en 349/349 tests groen. APK heeft package `nl.dragonhaven.app`, versionCode 10051, 367.048.207 bytes, SHA-256 `5b8ad4ea804e2765fde3b43c6a70e6ee10b8d3777fce685cc22ef7bfc7b78726` en vast certificaat `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`. Friends, tutorial en reduced motion passen op exact 360×640 dp. |
| 31-08-2026 | Productiemigratie 32 en onafhankelijke preflight | Codex, na jouw toestemming | [Migratierun 33414590573](https://github.com/Rakky88/DragonHaven/actions/runs/33414590573), `tool/release_server_preflight.ps1` | Exacte beginstand 31, publieke Auth-check, database-lint en dry-run groen; uitsluitend migratie 32 toegepast. Daarna 32/32 parity, 0 lintfouten, Auth health/settings 200/200, e-mailauth en applicatiehealth 200 met contractversie 1 en 94 ms gemeten klokafwijking bewezen. |
| 31-08-2026 | Openbare release v0.05.01 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.01), [taggate 33415060428](https://github.com/Rakky88/DragonHaven/actions/runs/33415060428) | Exact commit `b4a49a932e824aedba5031aca5f21675cda762a1` getagd. Remote assetnaam, grootte en SHA-256 zijn exact gelijk aan de lokale APK; versiegebonden en permanente latest-download geven HTTP 200. De taggate herhaalde productiepreflight, analyzer, 349 tests, signingcontrole en Play-ready AAB-build met succes. |
| 31-08-2026 | Post-release productiehealth v0.05.01 | Codex | [Healthrun 33415782470](https://github.com/Rakky88/DragonHaven/actions/runs/33415782470) | Auth en het privacyveilige applicatieendpoint zijn direct na publicatie groen; het dertig dagen bewaarde bewijsartifact is geüpload en er is geen storingsalert geopend. Productie staat gecontroleerd op 32/32. |
| 31-08-2026 | Eerste automatisch geplande stagingrestore | Codex | [Restorerun 33305301266](https://github.com/Rakky88/DragonHaven/actions/runs/33305301266), artifact `DragonHaven-weekly-staging-restore-2` | De zondagtrigger draaide zonder handmatige dispatch, gebruikte uitsluitend het geïsoleerde stagingproject en voltooide bevestigde login, actuele/historische back-up en conflictbeveiliging. De actieve rondgang duurde circa 7,3 seconden, de volledige job circa 20,4 seconden en het privacyarme artifact wordt dertig dagen bewaard. |
| 31-08-2026 | Gecontroleerde monitoring-alertdrill uitgevoerd | Codex, na jouw toestemming | commit `881d6f5`, [drillrun 33435265676](https://github.com/Rakky88/DragonHaven/actions/runs/33435265676) en [gesloten testissue #1](https://github.com/Rakky88/DragonHaven/issues/1) | De handmatige workflow accepteerde de exacte bevestiging, gebruikte geen Supabase- of repositorysecrets, leverde een duidelijk niet-productie `[DRILL]`-issue met appversie, fictieve correlation ID, ontvanger en runbooklink af, controleerde het contract, uploadde privacyarm bewijs en sloot de melding. Productie en de openbare apprelease zijn niet gewijzigd. |
| 31-08-2026 | Begrensd staging-loadprofiel op `main` gereed | Codex | `tool/staging_load_profile.dart`, `.github/workflows/staging-load.yml`, `test/staging_load_profile_test.dart`, `STAGING_LOAD_TEST.md` en `dragonhaven_spec_test.dart` | Alleen handmatige 100- en 1.000-user stappen zijn toegestaan; productie wordt dubbel geweigerd en 1.000 vereist eerst een groen 100-user artifact met maximaal 2% fouten. Iedere VU vereist een uniek bevestigd synthetisch account en gebruikt realistische ramp-up/think time. Rapporten bevatten app-/contract-/migratieversie, aantallen, veilige foutklassen, responsebytes en p50/p95/p99/max, nooit credentials, identities, responsebody of savedata. Planmodus, analyzer en alle 358 tests zijn groen; echte stagingload wacht op de synthetische accountpool en afzonderlijke runbevestiging. |
| 31-08-2026 | Fase 6 support- en privacyprocedure uitgewerkt | Codex | `SUPPORT_PRIVACY_OPERATIONS.md` en retentiecontract in `dragonhaven_spec_test.dart` | Minimale privacyarme intake en procedures voor accountverlies, e-mail, trade, cloudconflict, verwijdering, toekomstige refunds en misbruik zijn vastgelegd. De matrix koppelt 24-uurschat, vijf/30-dagen-cloudhistorie, 30-dagen-importherstel, 7-dagen-supportexport en accountdelete-cascades aan de implementatie. Migratie 33 en de testsupportflow hebben de fysieke importpurge inmiddels op staging bewezen. Duurzame sociale notificaties en Conclave Chronicle missen nog een door Rick gekozen algemene termijn; daarvoor volgt geen stille migratie. |
| 31-08-2026 | Fase 6 least-privilege supportkandidaat op staging bewezen | Codex, na jouw toestemming | migratie `202608310033_support_privacy_operations.sql`, `SUPPORT_PRIVACY_OPERATIONS.md`, `dragonhaven_spec_test.dart` en [stagingrun 33435243659](https://github.com/Rakky88/DragonHaven/actions/runs/33435243659) | Een alleen voor `service_role` uitvoerbare Keeper-ID-lookup retourneert minimale account-, save-, back-up- en geaggregeerde tradestatus zonder e-mail, naam, savebody, inventory, tegenpartij of itemdetails. Iedere poging vereist een casusnummer, operatoralias en vaste reden en schrijft een 30-dagen-log met uitsluitend de gehashte Keeper ID; dezelfde dagelijkse cleanup verwijdert verlopen logs en private importherstelkopieën. Staging apply/lint/preflight, volledige sociale E2E, analyzer, tests, staging-APK en bewijsupload zijn groen. Productie blijft 32/32 en de openbare app blijft v0.05.01; sociale notification- en Chronicle-retentie wachten bewust op beleid. |
| 31-08-2026 | Audittranche naar `main` en stagingvalidatie 33 | Codex, na jouw toestemming | commits `881d6f5` t/m `d20fb44` en [stagingrun 33435243659](https://github.com/Rakky88/DragonHaven/actions/runs/33435243659) | De exact toegestane zeven commits zijn als zuivere fast-forward naar `origin/main` gepusht. Migratie 33 is uitsluitend op het geïsoleerde stagingproject toegepast; production-safetycheck, migratiedry-run/apply, configuratiepush, serverpreflight, Friend Messages, Conclaves, Friends, trade, Group Adventure completion/reward/replay, analyzer, tests, staging-APK en driedaags bewijsartefact zijn groen. Productie en openbare release zijn onaangeraakt. |
| 31-08-2026 | Privacyarme testsupportflow op staging bewezen | Codex, na jouw toestemming | commit `9bea7f4`, [supportprivacyrun 33438895977](https://github.com/Rakky88/DragonHaven/actions/runs/33438895977), [bewijsartefact 9775464818](https://github.com/Rakky88/DragonHaven/actions/runs/33438895977/artifacts/9775464818) en [volledige staginggate 33438894645](https://github.com/Rakky88/DragonHaven/actions/runs/33438894645) | De exact bevestigde workflow gebruikte alleen staging en bewees migratie 33, weigering voor een normale sessie, minimale service-role-response, gehasht 30-dagen-inzagelog en fysieke cleanup van een verlopen sentinel. Het gecontroleerde bewijs was 413 bytes en bevatte alleen UTC/stagingstatus, booleans en de termijn; `production_targeted=false`, `raw_identifiers_recorded=false` en `credentials_recorded=false`. De volledige gate bewees daarnaast serverpariteit, sociale/Group Adventure-E2E, analyzer, alle tests, staging-APK en bewijsupload. Productie bleef 32/32 en de openbare release v0.05.01. |
| 31-08-2026 | Fase 7 app-/database-hotfixrunbook lokaal gebouwd | Codex | `ROLLBACK_HOTFIX_RUNBOOK.md` en runbookcontract in `dragonhaven_spec_test.dart` | De beslisroute gebruikt altijd een hogere appversie/`versionCode` of een nieuwe correctiemigratie, verandert toegepaste migraties en bestaande releases niet in-place en blokkeert op tests, staging, parity, lint, health, signing en ontbrekende toestemming. Destructieve migraties vereisen een apart herstelplan met bron, cutoff, hash, RPO/RTO, stagingrestore en afbreekcriteria; productie gebruikt nooit `db reset`. Flutter-analyzer en alle 360 tests zijn groen. De eerste staging-hotfixoefening blijft open en deze lokale tranche wijzigt geen externe omgeving. |
| 31-08-2026 | Google Play-appgroottebaseline lokaal gemeten | Codex | `APP_SIZE_AUDIT.md`, `tool/measure_android_artifact_size.ps1` en appgroottecontract in `dragonhaven_spec_test.dart` | Een vers gebouwde v0.05.01-AAB meet 361.758.898 bytes/345,00 MiB; universele afbeeldingen en audio zijn samen 284,99 MiB. Dragons (118,98 MiB), UI (52,45 MiB), audio (34,43 MiB) en chests (24,32 MiB) zijn de eerste doelen. De meting leest alleen ZIP-entrymetadata en legt een gratis beeldpilot, batchvolgorde, audiogrens en Play Console-eindmeting vast. Flutter-analyzer en alle 361 tests zijn groen. De build is niet gepubliceerd; productie en openbare app zijn ongewijzigd. |
| 31-08-2026 | Auditstatus en eigenaarschap geconsolideerd | Codex | `DRAGONHAVEN_POST_AUDIT_PLAN.md`, stagingruns `33438894645` en `33438895977`, supportbewijsartifact `9775464818` | Alle fasen tonen nu naast het gewogen percentage ook aantoonbaar afgerond werk, resterend werk, eigenaar, eerstvolgende overdracht en een strenge checklisttelling. Verouderde uitspraken over de alertdrill en importpurge zijn gecorrigeerd. Momentopname: Codex 30/66, Rick 13/49, samen/startvoorwaarden 8/32; totaal 51/147 afgerond en 96 open. Productie blijft 32/32 en de openbare release v0.05.01. |
| 01-09-2026 | Special Event-afteller, beknopte verrassingsbeloningen en expertiseclaim lokaal gebouwd | Codex | `adventure.dart`, `dragonhaven_systems.dart`, `adventure_hub_screen.dart`, `special_adventure_test.dart`, `new_feature_batch_widget_test.dart`, `household_provider_test.dart` | De actieve eventwindow voedt een live dagen/uren/minuten/seconden-teller op kaart en detail. Het kippenevent toont geen dubbele verhaaltekst of Special Chest-inhoud meer; relic/Music Chest hebben geen roll-/verrassingsuitleg. De configureerbare rewardbundle en claim geven elk +25 Might, Spirit en Arcana binnen de expertisegrens en tonen die op beschikbare, actieve en voltooide Adventures. Exact 360×640 dp is overflowvrij, analyzer meldt nul problemen en alle 363 tests slagen. Geen versie-, server-, migratie- of releasewijziging. |
| 01-09-2026 | Vanityframe behoudt volledige portretmaat en badge heeft geen houder | Codex | `online_account_access.dart`, `online_social_test.dart`, `new_feature_batch_widget_test.dart` | De gedeelde KeeperPortrait-compositie verkleint een ingelijst portret niet langer tot 64%. De gevraagde portret- en rarityringdiameter blijft gelijk aan de uitvoering zonder frame; het frame krijgt buitenom zijn eigen grotere canvas. De geselecteerde badge wordt rechtstreeks als transparante sprite getoond zonder witte cirkel, rand of houderschaduw. Account-keuze, Friends-kaart, vriendenprofiel, Draconomicon-, trialrecord- en tradeflow zijn regressiegetest. Analyzer meldt nul problemen en alle 363 tests slagen. Geen versie-, server-, migratie- of releasewijziging. |
| 01-09-2026 | Uitgeschakelde vanitykeuze blijft opgeslagen | Codex | `household_provider.dart`, `household_provider_test.dart`, `online_social_test.dart` | De restorelaag onderscheidt nu een expliciet opgeslagen `null` (bewust geen frame/badge) van een legacy save waarin het keuzeveld ontbreekt. Lokaal herstarten, cloudrestore en online profielpush behouden de lege keuze; bezit van de supporter-items blijft intact en oude saves krijgen nog veilig de historische standaardselectie. Analyzer meldt nul problemen en alle 365 tests slagen. Geen schema-, server-, migratie-, versie- of releasewijziging. |
| 01-09-2026 | Frostfable-wyrmling borst en alfaveiligheid hersteld | Codex | `frostfable_wyrmling_safe.webp`, `prepare_transparent_sprite.dart`, `audit_sprite_alpha.dart`, `selected_sprite_safety_test.dart` | De transparante breuk door de borst is via de ingebouwde imagegen-editroute gereconstrueerd als doorlopende ivoorwitte ijsschubben. De bestaande assetpipeline leverde een 1024px transparante WebP met minimaal 117px technische marge; een nieuwe test bewaakt vijf punten langs hals en borst naast de bestaande bronmarge- en renderpasses. Analyzer meldt nul problemen en alle 366 tests slagen. Geen codecontract-, server-, migratie-, versie- of releasewijziging. |
| 01-09-2026 | Gemiste Dragon Academy Dropout-reveal hersteld | Codex | `dragon_school_screen.dart`, `household_provider.dart`, `automatic_hatch_coordinator_test.dart`, `new_feature_batch_widget_test.dart`, `household_provider_test.dart` | Academy-results houden de presentatiequeue vast tot het eindrapport zichtbaar is; daarna bereikt de Dropout-presentatie aantoonbaar de echte full-screen achievementreveal. Saveschema 49 plant voor bestaande versie-48-Dropouts zonder pending reveal één herstelpresentatie in en voegt die na afhandeling en herstart niet opnieuw toe. Analyzer meldt nul problemen en alle 369 tests slagen. Geen appversie-, Supabase-, productie- of openbare releasewijziging. |
| 01-09-2026 | Golden Hour verdubbelt de Spectral-uitbroedkans | Codex | `day_phase.dart`, `pet.dart`, `household_provider.dart`, `dragonhaven_spec_test.dart`, `household_provider_test.dart` | De bestaande 1-op-20 basisworp krijgt voor een nog niet-Spectral, geschikt ei tijdens 17:00–19:00 lokale tijd een conditionele 1-op-19 bonusworp. Daarmee is de gecombineerde kans exact 1-op-10; buiten Golden Hour blijft zij 1-op-20. Tests bewaken beide tijdgrenzen, het echte hatchpad en de uitsluiting van Special Eggs zonder Spectral-variant. Analyzer meldt nul problemen en alle 373 tests slagen. Geen appversie-, server-, migratie-, productie- of openbare releasewijziging. |
| 01-09-2026 | Conclave-scroll en privéberichtmelding betrouwbaarder gemaakt | Codex | `conclave_screen.dart`, `online_account_provider.dart`, `notification_service.dart`, `dragonhaven_app.dart`, `social_phrase_translations.dart`, `notification_service_test.dart`, `online_social_test.dart` | De chat gebruikt een normale scroll-as, veilige bottom-follow en een volledig gelokaliseerde knop naar de nieuwste berichten. De notificatie-inbox wordt lichtgewicht iedere 15 seconden gepolld en direct bij resume ververst. Alleen een door Android geaccepteerde privéberichtmelding wordt acknowledged; mislukte delivery blijft retryable en concurrente refreshes dupliceren haar niet. Analyzer meldt nul problemen en alle 375 tests slagen. Echte terminated-app push blijft open onder fase 1 en vereist Firebase/FCM-config van Rick; geen versie-, server-, migratie-, productie- of openbare releasewijziging. |
| 01-09-2026 | v0.05.02 lokale releasecandidate | Codex, na jouw toestemming | commit `c0707ca1e36ea0189203f8eff056f389987fa96d`, `release-notes-v0.05.02.md`, `production-migrate-33.yml` en ondertekende APK | App- en zichtbare versie staan op v0.05.02 met versionCode 10052. Analyzer en 375/375 tests zijn groen. APK heeft package `nl.dragonhaven.app`, 367.052.619 bytes, SHA-256 `f657521a4e9b13ebca1c837a547616b19d395ce0f29265f68b2954753bde5e83` en vast certificaat `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`; 360×640 dp en reduced motion zijn op de emulator gecontroleerd. |
| 01-09-2026 | Productiemigratie 33 en onafhankelijke preflight | Codex, na jouw expliciete toestemming | [Migratierun 33562064314](https://github.com/Rakky88/DragonHaven/actions/runs/33562064314), `production-migrate-33.yml`, `release_server_preflight.ps1` | Exacte beginstand 32, publieke healthcheck, database-lint en dry-run waren groen; uitsluitend migratie 33 is toegepast. Daarna bewijzen workflow en onafhankelijke lokale preflight 33/33 parity, nul lintfouten, Auth health/settings 200/200, e-mailauth en applicatiehealth 200 met contractversie 1 en 76 ms gemeten klokafwijking. |
| 01-09-2026 | Openbare release en post-release health v0.05.02 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.02), [taggate 33562491443](https://github.com/Rakky88/DragonHaven/actions/runs/33562491443), [healthrun 33563056104](https://github.com/Rakky88/DragonHaven/actions/runs/33563056104) | Exact commit `c0707ca1e36ea0189203f8eff056f389987fa96d` is getagd. Remote assetnaam, 367.052.619 bytes en SHA-256 zijn gelijk aan lokaal; versiegebonden en permanente latest-download geven HTTP 200. De taggate herhaalde preflight, analyzer, 375 tests, vaste signing en Play-ready AAB. De post-releasecheck bevestigde Auth en applicatiehealth en bewaarde dertig dagen bewijs zonder storingsalert. |

| 02-09-2026 | Lokale post-v0.05.02 featuretranche opgebouwd | Codex | commits `3f5b015` t/m `65c65bc`, gerichte widget-/modeltests en `RANDOM_REWARDS_AND_ODDS.md` | Ascension-vereisten zijn duidelijker, tutorial/Draconomicon/kamerdiepte en Vanity zijn gecorrigeerd, Conclave-keepers en -chat zijn verfijnd, alle random rolls zijn gedocumenteerd en voltooide Adventures hebben een navigatiebadge. Dragon-emotes gebruiken lokale migratie 34. Niets is naar staging of productie gebracht; openbare versie blijft v0.05.02 en productie 33/33. |
| 02-09-2026 | Gescope Trial-ranglijsten lokaal gereed | Codex | commit `0e7ccc7`, migratie `202609020035_trial_rankings.sql`, `production-migrate-35.yml`, `trial_rankings_sheet.dart`, uitgebreide `staging_social_e2e.ps1` en drie groene gerichte tests | Trials bieden World en Friends per Grotvlucht, Ruïnebreker en Runenwever; Conclave Keepers biedt dezelfde vergelijking voor alle leden. De top 100 plus de eigen wereldpositie gebruikt alleen gepubliceerde scores en retourneert geen user-id, Keeper-ID of e-mail. Dart-analyse en PowerShell-parser zijn groen en de UI past op 360×640 dp. Nog door Codex na toestemming: migraties 34–35 op staging bewijzen, volledige gate draaien en pas bij afzonderlijke releasepermissie productie/release uitvoeren. Nog door Rick: alleen die externe toestemming wanneer gewenst. |
| 02-09-2026 | Keeper-badge linksonder over frame en portret geplaatst | Codex | commit `c0cf64f`, `online_account_access.dart` en gerichte compositietest in `online_social_test.dart` | De gedeelde KeeperPortrait tekent de badge voortaan linksonder bovenop de compositie. Met een geselecteerd frame kruist de badge aantoonbaar de portretgrens, zodat hij deels over het frame en deels over het portret ligt. Analyzer en de gerichte widgettest zijn groen; geen server-, migratie-, versie- of releasewijziging. |
| 02-09-2026 | v0.05.03 lokale releasecandidate | Codex, na jouw toestemming | commits `1528e15` en `8192514`, `release-notes-v0.05.03.md`, `production-migrate-36.yml` en ondertekende APK | App- en zichtbare versie staan op v0.05.03 met versionCode 10053. Analyzer en 402/402 tests zijn groen. APK heeft package `nl.dragonhaven.app`, 383.298.234 bytes, SHA-256 `1afcf367b2ece76e64d6b1dfa0b031d80d3d617611a2f3eb918467043d8a588c` en het vaste releasecertificaat; de productiebuild is op de Android-emulator gestart en Tower, hoofdmenu en Account Info zijn visueel gecontroleerd. |
| 02-09-2026 | Migraties 34–36 op staging bewezen | Codex | gestopte [lintgate 33629616836](https://github.com/Rakky88/DragonHaven/actions/runs/33629616836), migratie `202609020036_qualify_friend_message_notification.sql` en groene [stagingrun 33630222018](https://github.com/Rakky88/DragonHaven/actions/runs/33630222018) | De eerste run paste 34–35 toe en stopte veilig op de ambigue `kind`-verwijzing in `open_friend_messages`. Bestaande migraties zijn niet herschreven: migratie 36 kwalificeert de kolommen voorwaarts. De herstart bewees 36/36 parity, nul lintfouten, serverpreflight, Friend Messages/emotes, Conclaves, Friends/trade, Trial-ranglijsten, volledige Group Adventure completion/reward/replay, analyzer, tests, geïsoleerde staging-APK en bewijsupload. Productie bleef tot de aparte migratiegate op 33/33. |
| 02-09-2026 | Productiemigraties 34–36 en onafhankelijke preflight | Codex, na jouw toestemming | [migratierun 33631028441](https://github.com/Rakky88/DragonHaven/actions/runs/33631028441), `production-migrate-36.yml` en `release_server_preflight.ps1` | De workflow accepteerde uitsluitend exacte beginstand 33 en lokale pending-set 34–36. Publieke health, database-lint en dry-run waren groen vóór apply; daarna bewees zij 36/36 parity, nul lintfouten, Auth en applicatiehealth en uploadde zij dertig dagen privacyarm bewijs. |
| 02-09-2026 | Openbare release en post-release health v0.05.03 | Codex, na jouw toestemming | [release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.03), [taggate 33631376907](https://github.com/Rakky88/DragonHaven/actions/runs/33631376907) en [healthrun 33632227689](https://github.com/Rakky88/DragonHaven/actions/runs/33632227689) | Exact commit `8192514a7ca590e6cc50681867c8f98df82ee1fa` is getagd. Remote `DragonHaven.apk`, grootte en SHA-256 zijn exact gelijk aan lokaal; versiegebonden en permanente latest-download geven HTTP 200. De taggate herhaalde productiepreflight, analyzer, 402 tests, vaste signing en Play-ready AAB. De losse healthrun bevestigde Auth en applicatiehealth, bewaarde bewijs en opende geen storingsalert. |
| 02-09-2026 | v0.05.04 lokale releasecandidate en visuele controle | Codex, na jouw toestemming | commit `6ccdd865bc510bc0b18b77b1954ecafaf4f33434`, `release-notes-v0.05.04.md`, compacte widgettests en ondertekende APK | App- en zichtbare versie staan op v0.05.04 met versionCode 10054. Analyzer en 402/402 tests zijn groen. APK heeft package `nl.dragonhaven.app`, 383.298.234 bytes, SHA-256 `9e9a9b8d0befb1280070dfa53a34045e7f485c37541b81dc1f6f711e9ea436ad` en het vaste releasecertificaat `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`. De echte release-APK toont op de emulator met reduced motion drie volledige emoteprijzen en de Special Adventure-afteller in de kaart links van Start. De onafhankelijke lokale productiepreflight bewees 36/36, nul lintfouten en groene Auth-/applicatiehealth; er was geen nieuwe migratie. |
| 02-09-2026 | Openbare release en post-release health v0.05.04 | Codex, na jouw toestemming | [release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.04), [taggate 33636356574](https://github.com/Rakky88/DragonHaven/actions/runs/33636356574) en [healthrun 33637454654](https://github.com/Rakky88/DragonHaven/actions/runs/33637454654) | Exact commit `6ccdd865bc510bc0b18b77b1954ecafaf4f33434` is getagd. Na bewezen bytegelijke cleanup bevat de release exact één stabiele `DragonHaven.apk`; remote grootte en SHA-256 zijn gelijk aan lokaal en beide openbare downloadroutes geven HTTP 200. De taggate herhaalde productiepreflight, analyzer, 402 tests, vaste signing en Play-ready AAB. De losse healthrun bevestigde Auth en applicatiehealth, bewaarde dertig dagen bewijs, opende geen storingsalert en laat productie/staging ongewijzigd op 36/36. |
| 02-09-2026 | Levende Special-content- en kansendocumentatie geborgd | Codex | `SPECIAL_EVENTS_CHESTS_AND_EGGS.md`, `RANDOM_REWARDS_AND_ODDS.md`, `tool/reference_documentation_guard.dart`, `reference_documentation_test.dart` en `AGENTS.md` | De Engelstalige catalogus beschrijft de geplande Golden Wings-eventwindow en rewards, beide vrijgelaten-draakroutefamilies, alle tien chesttypes, alle vier eggtypes en de huidige beperking dat een Special Chest/Egg nog geen stabiele eventdefinitie-ID bewaart. Beide naslagwerken hebben een unsigned 64-bit bronvingerafdruk. Relevante implementatiewijzigingen zonder opnieuw beoordeelde documentatie laten de test falen; event-/egg-/chestwijzigingen en nieuwe random pools moeten de overeenkomstige bronlijst en Markdown in dezelfde wijziging meenemen. Analyzer en alle 407 tests zijn groen. Geen appversie-, server-, migratie-, productie- of releasewijziging. |
| 02-09-2026 | Conclave-chatcomposer compact en rustig herontworpen | Codex | `conclave_screen.dart`, `social_phrase_translations.dart` en `online_social_test.dart` | De dubbele afgeronde houder en drie brede standaardknoppen zijn vervangen door één lichte invoerpill met compacte deel- en emoteacties en een losse ronde verzendknop. Op minder dan 350 dp gebruikt de composer de korte hint “Message…”/“Bericht…”; alle zes overige talen hebben dezelfde compacte vertaling. De sendknop is visueel uitgeschakeld zolang het bericht leeg is. Een 320×800-widgetpass bewaakt eenregelige hint, 48–52 dp hoogte, actielijn en actieve/inactieve sendstatus. Analyzer, lokalisatiepoort en alle sociale regressietests zijn groen; samen met de overige groene volledige run zijn 407/407 tests gedekt. Geen appversie-, server-, migratie-, productie- of releasewijziging. |
| 02-09-2026 | v0.05.05 Android-only releasecandidate bewezen | Codex, na jouw toestemming | `release-notes-v0.05.05.md`, 405 tests, ondertekende `DragonHaven.apk`, emulatorcontrole en `release_server_preflight.ps1` | De iPhoneknop is uit de app verwijderd; About toont alleen de permanente Android-link en `Update`. Appversie/versionCode zijn 0.05.05/10055. APK-grootte is 383.331.062 bytes, SHA-256 `1e60b2c8b5527ebae051dcc296f245956eb031de45b66c6730f87421cb2694e6` en het vaste releasecertificaat komt exact overeen. Installatie over de bestaande app, splash, hoofdscherm, versie en Android-only About-kaart zijn op emulator bewezen. Analyzer en 405/405 tests zijn groen. Productie blijft zonder nieuwe migratie op 36/36, nul lintfouten en gezonde Auth-/applicatie-endpoints. |
| 02-09-2026 | v0.05.05 openbaar; taggate stopte vóór signing | Codex | [release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.05) en [taggate 33648597144](https://github.com/Rakky88/DragonHaven/actions/runs/33648597144) | Release en APK wijzen naar commit `5600e183f177af99b0a492ca57335e36c5f1bee8`; remote assetnaam, grootte en SHA-256 zijn exact gelijk aan lokaal en beide downloadroutes geven HTTP 200. De productieserverpreflight en analyzer waren groen. De Linux-runner liet 404 tests slagen en stopte veilig op één platformafhankelijke CRLF/LF-documentatiefingerprint, vóór signing en zonder servermutatie. De gepubliceerde release blijft onveranderd als historisch bewijs; correctie volgt uitsluitend met een hoger versienummer. |
| 02-09-2026 | v0.05.06 Android-hotfix openbaar en volledig groen | Codex, na jouw toestemming | [release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.06), [taggate 33650746606](https://github.com/Rakky88/DragonHaven/actions/runs/33650746606), [healthrun 33651528845](https://github.com/Rakky88/DragonHaven/actions/runs/33651528845), `release-notes-v0.05.06.md` en `reference_documentation_guard.dart` | De bronfingerprint normaliseert regeleinden vóór hashing en een regressietest bewijst gelijke LF/CRLF-uitkomsten. Appversie/versionCode zijn 0.05.06/10056. De APK is 383.331.062 bytes met SHA-256 `cced52519b96b961b9bcce4adf707d6eab150a3e06f591f3469a5386333ee04c`; remote asset en beide HTTP 200-downloadroutes zijn bewezen. Emulatorcontrole toont v0.05.06 en uitsluitend `Copy download link` en `Update`. De taggate herhaalde productiepreflight, analyzer, 406 tests, vaste signing, Play-ready AAB en artifactcontrole groen. De healthrun bevestigde Auth/applicatiehealth zonder storingsalert; productie bleef 36/36. |
| 02-09-2026 | Trial-scoremultiplier door relevante expertise lokaal gereed | Codex | `trial.dart`, `dragonhaven_systems.dart`, `trial_game_screen.dart`, `adventure_hub_screen.dart`, drie regressietestbestanden en `RANDOM_REWARDS_AND_ODDS.md` | Iedere Trial gebruikt exact één vak: Spirit voor Cavern Flight, Might voor Ruin Breaker en Arcana voor Runeweaver. De formule is `round half up(ruwe score × (1 + expertise/1000))`; 5 expertise is dus ×1,005 en 300 expertise ×1,300. De eindscore stuurt rang, reward, dragon/account-best en online rankings. De draakkiezer toont de multiplier vooraf en de resultaatskaart toont ruwe score × multiplier onder het eindtotaal. Relevante expertise wordt vóór de reward vastgelegd, zodat nieuw verdiende punten pas een volgende run helpen. Analyzer, 69 gerichte tests en alle 407 regressietests zijn groen; bewaakte referentiedocumentatie is gesynchroniseerd. Geen appversie-, server-, migratie-, productie- of openbare releasewijziging. |
| 02-09-2026 | Lege-nestcollectie en Emberbun Spirit lokaal vernieuwd | Codex | `egg_collection_preferences.dart`, `rooftop_nest_screen.dart`, `inventory_screen.dart`, `emberbun_spirit_safe.webp`, `dragon_lineage.dart`, `dragon_art.dart`, `remove_generator_checkerboard.dart`, `AGENTS.md` en regressietests | Tikken op een leeg nest opent nu een compacte tegel- of lijstweergave. Beide tonen per ei de echte broedtijd en vage hint; ontvangen datum en broedtijd gebruiken exact dezelfde opgeslagen, opnieuw aanklikbare omkeersortering als Inventory. De dubbele naam Everwarm Hearthheart is vervangen door Everwarm Hearthkeeper (Nederlands: Eeuwarm Haardhoeder). De opnieuw gerenderde losse Spirit-sprite heeft echte alpha, veilige 1024px-marges en kop plus lichaamsas naar rechts; de ingebakken generatorchecker is technisch verwijderd en op blauw gecontroleerd. De verplichte rechtsrichting is vastgelegd voor alle toekomstige draakrenders. Analyzer, gerichte nest-/content-/spritechecks en alle 408 regressietests zijn groen; beide bewaakte gameplayreferenties zijn na inhoudelijke controle gesynchroniseerd. Geen appversie-, server-, migratie-, productie- of openbare releasewijziging. |
| 02-09-2026 | v0.05.07 lokale releasecandidate bewezen | Codex, na jouw toestemming | `release-notes-v0.05.07.md`, 408 tests, ondertekende `DragonHaven.apk`, emulatorcontrole en `release_server_preflight.ps1` | App- en zichtbare versie staan op v0.05.07 met versionCode 10057. APK heeft package `nl.dragonhaven.app`, 384.170.857 bytes, SHA-256 `def7b0b6595ad68f9e5316b3be2e1b5a44f8fb407aeb378bfba4ef5e30b1c871` en het vaste certificaat `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`. De echte release-APK is over de bestaande app geïnstalleerd; Tower, de lege-nestterugval en About v0.05.07 zijn visueel gecontroleerd. Analyzer en 408/408 tests zijn groen. Productie en staging blijven zonder nieuwe migratie op 36/36, met nul lintfouten en gezonde Auth-/applicatiehealth. |
| 02-09-2026 | v0.05.07 openbaar en volledig groen | Codex, na jouw toestemming | [release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.07), [taggate 33658910426](https://github.com/Rakky88/DragonHaven/actions/runs/33658910426) en [healthrun 33659821612](https://github.com/Rakky88/DragonHaven/actions/runs/33659821612) | Exact commit `2944fd1d521a665acf7b19289d61a3549dd2e928` is getagd. Remote `DragonHaven.apk` heeft exact de lokale grootte van 384.170.857 bytes en SHA-256 `def7b0b6595ad68f9e5316b3be2e1b5a44f8fb407aeb378bfba4ef5e30b1c871`; de versiegebonden en permanente latest-download geven HTTP 200. De taggate herhaalde productiepreflight, analyzer, 408 tests, vaste signing, Play-ready AAB en artifactupload groen. De losse healthrun bevestigde Auth en applicatiehealth, uploadde bewijs en opende geen storingsalert. Productie en staging bleven ongewijzigd op 36/36. |
| 02-09-2026 | Trial-multiplier lokaal verwijderd en Spectral-reparaties bewezen | Codex | `trial.dart`, `dragonhaven_systems.dart`, `adventure_hub_screen.dart`, `trial_game_screen.dart`, Trial-regressies, `selected_sprite_safety_test.dart` en beide levende referentiedocumenten | De ingeleverde minigamescore is weer rechtstreeks de eindscore voor rang, reward, dragon/account-best en online rankings; de multiplier-UI en -modelvelden zijn verwijderd. Een regressie met bestaande Expertise bewijst dat score 250 exact 250 blijft. Emberbun Spirit, Starforged Arcana en Frostfable Wyrmling gebruiken voor Spectral dezelfde herstelde standalone sprite; de runtime voegt alleen kleurfilter en aura toe. Alle 87 geselecteerde vormen zijn vijfmaal in normaal/Spectral en kleur/silhouet gerenderd, specifieke Frostfable-/Starforged-alphacontroles slagen, analyzer meldt nul problemen en alle 407 tests zijn groen. Geen versie-, server-, migratie-, productie- of openbare releasewijziging. |
| 02-09-2026 | v0.05.08 lokale releasecandidate bewezen | Codex, na jouw toestemming | `release-notes-v0.05.08.md`, 407 tests, ondertekende `DragonHaven.apk`, emulatorcontrole en `release_server_preflight.ps1` | App- en zichtbare versie staan op v0.05.08 met versionCode 10058. APK heeft package `nl.dragonhaven.app`, 384.170.857 bytes, SHA-256 `29af64061bffb2a4c56db5223d6c6cf4aa5b2a11f074c75ca03689b91fda685a` en het vaste certificaat `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`. De echte release-APK is over de bestaande emulator-app geïnstalleerd; Tower, About v0.05.08 en de Trial-pagina zonder multiplier zijn visueel gecontroleerd. Analyzer, referentiedocumentatiegates en 407/407 tests zijn groen. Productie en staging blijven zonder nieuwe migratie op 36/36, met nul lintfouten en gezonde Auth-/applicatiehealth. |
| 02-09-2026 | v0.05.08 openbaar en volledig groen | Codex, na jouw toestemming | [release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.08), [taggate 33682174544](https://github.com/Rakky88/DragonHaven/actions/runs/33682174544) en [healthrun 33682959208](https://github.com/Rakky88/DragonHaven/actions/runs/33682959208) | Exact commit `1b6e941add5121ef8a700c31da79949a72613d41` is getagd. Remote `DragonHaven.apk` heeft exact de lokale grootte van 384.170.857 bytes en SHA-256 `29af64061bffb2a4c56db5223d6c6cf4aa5b2a11f074c75ca03689b91fda685a`; de versiegebonden en permanente latest-download geven HTTP 200 en v0.05.08 is Latest. De taggate herhaalde productiepreflight, analyzer, 407 tests, vaste signing, Play-ready AAB en artifactupload groen. De losse healthrun bevestigde Auth en applicatiehealth, uploadde bewijs, sloot een eventueel hersteld alert en opende geen storingsalert. Productie en staging bleven ongewijzigd op 36/36. |
| 03-09-2026 | Wyrmling-level- en Ascension-informatie ontdubbeld | Codex | `dragon_tower_screen.dart`, `ascension_requirements.dart` en twee widgetregressies | De My Dragons-detailkaart toont huidig level, totale XP en voortgang naar het volgende level ieder nog maar één keer. De evolutieregel noemt compact `Ascended · Level 7`; daaronder staat alleen de aanvullende totale-Expertise-eis met status en voortgangsbalk. Het herbruikbare losse Ascension-paneel behoudt bewust beide gates. Een componenttest en een volledige My Dragons-integratietest bewaken dat actuele XP en de levelgate niet opnieuw in het compacte blok verschijnen. Analyzer en 409/409 tests zijn groen. Geen appversie-, server-, migratie-, productie- of openbare releasewijziging. |
| 04-09-2026 | v0.05.09 lokale releasecandidate bewezen | Codex, na jouw toestemming | `release-notes-v0.05.09.md`, `DRAGON_ARTWORK_AUDIT.md`, bewaakte gameplayreferenties, 411 tests, ondertekende `DragonHaven.apk` en `release_server_preflight.ps1` | App- en zichtbare versie staan op v0.05.09 met versionCode 10059. De Wyrmling-evolutiekaart is ontdubbeld, Cluckatrice is een afzonderlijk Special Event-type en 104 tussenvormen gebruiken gereviewde standalone art. De APK heeft package `nl.dragonhaven.app`, 404.664.007 bytes, SHA-256 `a30ee7c438c74f39f3c332cbcd2a070952489d53fef9f5cb6d13e02e9baada24` en het vaste certificaat `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`. Analyzer, 411/411 tests, spritegates, documentgates en emulatorupdate zijn groen. Productie blijft ongewijzigd op 36/36 migraties met nul lintfouten en gezonde Auth-/applicatiehealth. |
| 04-09-2026 | v0.05.09 openbaar en volledig groen | Codex, na jouw toestemming | [release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.09), [taggate 33846472807](https://github.com/Rakky88/DragonHaven/actions/runs/33846472807) en [healthrun 33847137918](https://github.com/Rakky88/DragonHaven/actions/runs/33847137918) | Exact commit `ca9afac5f541b7e9f192a0ebe63278dc70467f0e` is getagd. Remote `DragonHaven.apk` heeft exact de lokale grootte van 404.664.007 bytes en SHA-256 `a30ee7c438c74f39f3c332cbcd2a070952489d53fef9f5cb6d13e02e9baada24`; de versiegebonden en permanente latest-download geven HTTP 200 en v0.05.09 is Latest. De taggate herhaalde productiepreflight, analyzer, 411 tests, vaste signing, Play-ready AAB en artifactupload groen. De losse healthrun bevestigde Auth en applicatiehealth, uploadde bewijs, sloot een eventueel hersteld alert en opende geen storingsalert. Productie en staging bleven ongewijzigd op 36/36. |
| 05-09-2026 | v0.05.10 lokale releasecandidate bewezen | Codex, na jouw toestemming | `release-notes-v0.05.10.md`, vijf definitief goedgekeurde draaksprites, Long Adventure- en Trial-streakregressies, 412 tests, ondertekende `DragonHaven.apk` en `release_server_preflight.ps1` | App- en zichtbare versie staan op v0.05.10 met versionCode 10060. Long Adventures gebruiken 15 minuten reductie per passend Expertise-punt en de Trial-constellatie telt strikt maximaal één dagbijdrage per lokale kalenderdag, ook na claimen en herstart. De Wyrmling-levelkaart blijft ontdubbeld. APK heeft package `nl.dragonhaven.app`, 404.899.023 bytes, SHA-256 `05cca29724fb22d1573ed7d34c5db140811f02273a43e9dfb33432ebea1d64de` en vast certificaat `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`. De echte release-APK is als update gestart op de emulator en toont v0.05.10. Analyzer, 412/412 tests, sprite- en documentgates zijn groen. Productie blijft ongewijzigd op 36/36 migraties met nul lintfouten en gezonde Auth-/applicatiehealth. |
| 05-09-2026 | v0.05.10 openbaar en volledig groen | Codex, na jouw toestemming | [release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.10), [taggate 33952489143](https://github.com/Rakky88/DragonHaven/actions/runs/33952489143) en [healthrun 33952879963](https://github.com/Rakky88/DragonHaven/actions/runs/33952879963) | Exact commit `cdbeaa6a4427e69e92f4f7aaf2fe96a249c8d0ee` is getagd en v0.05.10 is Latest. Remote `DragonHaven.apk` heeft exact de lokale grootte van 404.899.023 bytes en SHA-256 `05cca29724fb22d1573ed7d34c5db140811f02273a43e9dfb33432ebea1d64de`; releasepagina, versiegebonden APK en permanente latest-download geven HTTP 200. De taggate herhaalde productiepreflight, analyzer, 412 tests, vaste signing, Play-ready AAB en artifactupload groen. De losse healthrun bevestigde Auth en applicatiehealth, uploadde bewijs, sloot een eventueel hersteld alert en opende geen storingsalert. Productie en staging bleven ongewijzigd op 36/36. |
| 05-09-2026 | v0.05.11 lokale releasecandidate bewezen | Codex, na jouw toestemming | `release-notes-v0.05.11.md`, `REDEEM_CODES.md`, zestig nieuwe emotesprites, 414 tests, ondertekende APK/AAB, emulatorcontrole en `release_server_preflight.ps1` | App- en zichtbare versie staan op v0.05.11 met versionCode 10061. Chest en Trial S+ bevatten ieder 55 unieke winbare emotes; samen met 30 packemotes zijn er 140. Een test bewaakt dat publieke release notes geen redeemcodes of aankondigingen daarvan bevatten. APK heeft package `nl.dragonhaven.app`, 416.935.961 bytes, SHA-256 `e2d78232df3851215fb74f5f54407215443652e07bcd176fd930bcc3d61cf8e2` en vast certificaat `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`; de Play-ready AAB is 411.663.903 bytes met SHA-256 `6611bb90359793a6785a202eb3feaf95b651a58086493f403eae5eb86a3438cc`. De echte APK is als update gestart op de emulator. Analyzer, 414/414 tests, sprite- en documentgates zijn groen. De onafhankelijke productiepreflight bewijst 36/36, nul lintfouten en HTTP 200 voor Auth en applicatiehealth; er is geen servermigratie. |
| 05-09-2026 | v0.05.11 openbaar en volledig groen | Codex, na jouw toestemming | [release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.11), [taggate 33967651302](https://github.com/Rakky88/DragonHaven/actions/runs/33967651302) en [healthrun 33968083818](https://github.com/Rakky88/DragonHaven/actions/runs/33968083818) | Exact commit `95881fb02d74b1fa10694578e8e0e2a09ce94208` is getagd en v0.05.11 is Latest. De release bevat exact één `DragonHaven.apk`; remote grootte 416.935.961 bytes en SHA-256 `e2d78232df3851215fb74f5f54407215443652e07bcd176fd930bcc3d61cf8e2` zijn gelijk aan lokaal en beide downloadroutes geven HTTP 200. De publieke notes bevatten geen redeemcodes. De taggate herhaalde productiepreflight, analyzer, 414 tests, vaste signing, Play-ready AAB en artifactupload groen. De losse healthrun bevestigde Auth en applicatiehealth, uploadde bewijs, sloot een eventueel hersteld alert en opende geen storingsalert. Productie en staging bleven ongewijzigd op 36/36. |
| 05-09-2026 | Auditfase 4A economyfundament lokaal gereed | Codex | `202609050037_economy_authority_foundation.sql`, `SERVER_AUTHORITATIVE_ECONOMY.md`, `staging-economy-foundation.yml`, `staging_economy_foundation_e2e.ps1` en `server_authoritative_economy_test.dart` | De dormante kandidaat gebruikt bestaande wallet-/egg-/dragonrecords en voegt item-/chestinstances, unieke rewardclaims, payloadgebonden idempotency, rate limiting, append-only ledger, RLS/revokes en een fail-closed `legacy_client`/`shadow`/`server`-contract toe. Volledige accountverwijdering kan economydata cascaderen; losse ledgerwijzigingen blijven verboden. De exact staging-only workflow blokkeert productie en iedere begin-/pendingset anders dan 36→37, en controleert voor/na health, parity, lint, clienttoegang en uitgeschakelde mutaties. PowerShell parse, analyzer en 424/424 tests zijn groen. Niets is gepusht, toegepast of uitgebracht; staging en productie blijven 36/36 en de app v0.05.11. |
| 05-09-2026 | Fase 4A stagingapply stopte veilig op SQL-lint | Codex, na jouw toestemming | [stagingrun 33981050406](https://github.com/Rakky88/DragonHaven/actions/runs/33981050406), commit `aa1a571` en migratie 37 | Exacte beginstand 36, productieblok, health, pre-lint en dry-run waren groen; migratie 37 werd op staging toegepast. De verplichte post-apply lint vond daarna dat `current_time` als PostgreSQL-keyword een `timetz` opleverde voor een `timestamptz`-kolom. De workflow stopte vóór verdere E2E. Er was geen playerwaardemutatie: globale mutaties stonden uit, alle keepers bleven legacy en productie bleef 36. De toegepaste migratie is niet herschreven. |
| 05-09-2026 | Fase 4A forward-only hersteld en volledig op staging bewezen | Codex, binnen dezelfde toegestane stagingtranche | [stagingrun 33981322674](https://github.com/Rakky88/DragonHaven/actions/runs/33981322674), commit `419019b` en migratie 38 | De exact begrensde herstelpoort accepteerde uitsluitend staging 37→38. `v_now timestamptz` corrigeert de klokvariabele voorwaarts. Daarna zijn 38/38 parity, nul database-lintfouten, public Auth/apphealth, zes RLS-tabellen zonder directe clientrechten, scoped read-only RPC, append-only trigger, timestampfix, `legacy_client`-defaults en een geweigerde mutatie zonder achtergebleven request bewezen. Het privacyarme artifact wordt dertig dagen bewaard. Productie bleef gezond en ongewijzigd op 36/38; app en release bleven v0.05.11. |
| 05-09-2026 | Fase 4A contractdrill stopte vóór uitvoering | Codex | [stagingrun 33981869474](https://github.com/Rakky88/DragonHaven/actions/runs/33981869474) en commit `ac39d29` | De eerste rollback-only drill stopte tijdens de lokale bewijsuitvoer omdat de workflow de map `staging/` nog niet vóór `Tee-Object` had aangemaakt. Hij bereikte de E2E-query niet, migreerde niets en raakte geen database- of playerwaarde. Commit `e1e9c50` maakte de bewijsmap vóór de preflight aan. |
| 05-09-2026 | Fase 4A rollback-only contractdrill groen | Codex, na jouw toestemming | [stagingrun 33981974136](https://github.com/Rakky88/DragonHaven/actions/runs/33981974136), [bewijsartifact 9974025042](https://github.com/Rakky88/DragonHaven/actions/runs/33981974136/artifacts/9974025042) en commits `ac39d29`–`e1e9c50` | De productie-geblokkeerde drill bewees op staging 38/38, nul lintfouten, Auth/apphealth vóór en na, oud-clientweigering, een nieuw idempotent verzoek, replay met exact hetzelfde resultaat, weigering van dezelfde ID met andere payload en rate limiting. Alle tijdelijke featureflag-, authority-, request- en bucketwijzigingen draaiden binnen één opzettelijk teruggerolde subtransactie; de nacheck bewees dat niets achterbleef. Het privacyarme bewijs van 1.972 bytes wordt dertig dagen bewaard. Analyzer en 426/426 lokale tests zijn groen; productie bleef 36/38 en app/release v0.05.11. |
| 05-09-2026 | Fase 4B eerste concrete aankoop lokaal gereed | Codex | lokale migratie `202609050039_dormant_vanity_chest_purchase.sql`, `server_economy_repository.dart`, `staging-vanity-chest-purchase.yml`, economy-/restoretests en uitgebreid rollback-E2E-script | De nog ongepushte RPC koopt alleen capped, non-tradeable Portrait-, Title- en Music-chests tegen exact 100 gems, 100 coins en 250 gems. Eén transactie vergrendelt de keeper, valideert collection cap en saldo, debiteert de revisioned wallet, creëert één chestinstance, schrijft twee append-only ledgerregels, verhoogt serverrevision en bewaart de response onder de request-ID. Lokaal zijn featureflag `false`, verloren antwoord/reconnect, gelijktijdige dubbele submit, strikte responsevalidatie en bescherming van server-owned wallet/chests tegen oude cloudsaves bewezen. De exacte 38→39-workflow en rollback-only stagingdrill staan klaar, maar zijn niet gepusht of uitgevoerd. Analyzer en 436/436 tests zijn groen; staging heeft 38 toegepast, productie 36 en de lokale repository bevat migratie 39. App/release blijven v0.05.11. |
| 06-09-2026 | Trial-constellatiedagen aan echte completion gekoppeld | Codex | saveschema 51, `trialStreakCreditedDayKeys`, streaknormalisatie en drie nieuwe providerregressies | Iedere gevulde dag heeft nu een opgeslagen dagbewijs dat uitsluitend in `completeTrial` ontstaat. Alleen datumverversing gedurende acht dagen blijft 0/7; meerdere Trials op dezelfde lokale kalenderdag blijven 1/7. Bij het laden verwijdert de migratie aantoonbaar een vooruitgeschoven dag wanneer `trialStreakLastDayKey` geen overeenkomende laatst voltooide Trial heeft, terwijl geldige bestaande streaks behouden blijven. Analyzer, 111 gerichte provider-/widgettests en alle 439/439 tests zijn groen. De bewaakte kans- en Special-contentdocumenten zijn na inhoudelijke controle opnieuw gesynchroniseerd; odds en eventinhoud veranderden niet. Geen appversie-, server-, migratie-, productie- of openbare releasewijziging. |
| 06-09-2026 | Alle bestaande redeemcodes gedeactiveerd | Codex | lege `redeemCodeCatalog`, `REDEEM_CODES.md` en catalogus-/documentatieregressies | De redemption-infrastructuur blijft beschikbaar voor toekomstige campagnes, maar de actieve catalogus bevat nul codes. Alle eerder uitgegeven codes geven voortaan dezelfde inactieve uitkomst en kunnen geen pack of emote meer verlenen; al rechtmatig verkregen items worden niet afgenomen. Het Engelstalige levende naslagwerk vermeldt expliciet dat er geen actieve codes zijn en de bronfingerprint is bijgewerkt. Analyzer, 102 gerichte tests en alle 439/439 tests zijn groen. Geen appversie-, server-, migratie-, productie- of openbare releasewijziging. |
| 07-09-2026 | Vijf seasonal events lokaal volledig ingebouwd | Codex | `NEW_EVENTS_PLAN.md`, `SPECIAL_EVENTS_CHESTS_AND_EGGS.md`, migratie `202609070040_seasonal_events.sql`, saveschema 53, vijf event-Trials, vijf Special families, vijf chest-/eggsets, eventaudio, ranglijsten/Chronicle, previewcodes en de Valentijns-/Pride-serverflows | Halloween, Kerst, Nieuwjaar, Valentijn en Pride volgen hun volledig goedgekeurde kalender-, adventure-, reward-, Trial- en rankingcontracten. Iedere Trial heeft een eigen schermvullende achtergrond, zes thematische gameplayassets, iconen, animaties en feedbackaudio; de 30 eerder goedgekeurde drakenvormen en alle event-cutouts slagen voor alpha en safe area. Alle vaste eventteksten, achievements en Adventures bestaan in acht talen. Analyzer meldt nul problemen, 455/455 tests zijn groen en een debug-APK van 541.353.825 bytes compileert. De werkelijk gebundelde seasonal toevoeging is circa 57,0 MiB; grote bronplaten worden niet verscheept. Migratie 40 is nog niet gepusht of toegepast: database-lint en live E2E horen bij een later expliciet toegestane staginggate. Productie blijft 36, staging 38, app/release v0.05.11. |

| 07-09-2026 | Seasonal event-UI in drie visuele rondes verfijnd | Codex | `seasonal_trial_game.dart`, `adventure_hub_screen.dart`, `seasonal_trial_rankings_sheet.dart`, vijf expliciete event-assetmappen en aangescherpte widget-/alphatests | Trials tonen nu eventembleem, spritefasepad, subtiele ambient motion en een thematische uitslag; Special Adventure-, Valentijn-, Pride- en rankingpresentaties hergebruiken de goedgekeurde eventart. Valentijn/Pride Trial-iconen zijn zonder afgesneden onderfragment en met echte alpha opnieuw opgebouwd; Nieuwjaar/Pride chest-/eggcutouts hebben extra randruimte. 320×640-dekking bewijst alle vijf Trials en de eventgate controleert alle buitenranden. Analyzer en 456/456 tests zijn groen. Geen versie-, server-, migratie-, productie- of releasewijziging. |
| 07-09-2026 | Eerste seasonal stagingpoort stopte veilig op lint | Codex, binnen jouw releasetoestemming | [stagingrun 34072050993](https://github.com/Rakky88/DragonHaven/actions/runs/34072050993), migratie 40 en forward-only migratie 41 | De workflow bewees de exacte 38→40-set, groene voorafgaande health/lint en paste 39–40 uitsluitend op staging toe. De verplichte nacheck vond daarna twee ambigue PL/pgSQL-identifiers in de previewredeem- en Pride-progressfuncties en stopte vóór seasonal E2E. Productie bleef gezond op 36 en er is geen release gepubliceerd. Migratie 41 vervangt alleen deze twee functies met ondubbelzinnige identifiers; een 40→41-herstelpoort moet nog volledig groen worden voordat productie of v0.05.13 verdergaat. |
| 07-09-2026 | Seasonal servercontracten forward-only hersteld en uitgerold | Codex, binnen jouw releasetoestemming | [stagingrun 34072959455](https://github.com/Rakky88/DragonHaven/actions/runs/34072959455), [productierun 34073058141](https://github.com/Rakky88/DragonHaven/actions/runs/34073058141), commit `70bc6f6` en migratie 41 | De begrensde 40→41-stagingpoort maakte beide functies ondubbelzinnig en bewees daarna 41/41 parity, nul lintfouten, RLS/revokes, de dormante vanity-aankoop in rollback, een gesimuleerde seasonal Trial met ranking en volledige cleanup plus Auth/apphealth. Pas daarna bracht de aparte productiepoort exact 36→41 over; dry-run, apply, parity, lint en health waren groen. Een onafhankelijke lokale productiepreflight bevestigde 41 migraties, nul lintfouten en HTTP 200 voor Auth en applicatiehealth. Economy-activatie bleef uit en er zijn geen bestaande spelerwaarden gemigreerd. |
| 07-09-2026 | v0.05.13 gepubliceerd; taggate vond statische releaseverwachting | Codex, binnen jouw releasetoestemming | [release v0.05.13](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.13) en [taggate 34073419192](https://github.com/Rakky88/DragonHaven/actions/runs/34073419192) | De ondertekende APK van 477.701.825 bytes met SHA-256 `3636138ff7cf5cbe65eda154c0ff2ffc31fb2321e9f05fefedc808daee5070d2` is exact en openbaar. Productiepreflight en analyzer waren groen; 457 tests slaagden. Eén loadprofieltest verwachtte nog migratie 40 terwijl de repository en gezonde productie terecht op 41 stonden, waardoor de gate vóór signing/AAB stopte. De gepubliceerde historische release wordt niet herschreven. v0.05.14 corrigeert uitsluitend deze forward-validatie, verhoogt versie/versionCode en herhaalt alle gates. |
| 07-09-2026 | v0.05.14 forward-only releasecandidate volledig lokaal groen | Codex, binnen jouw releasetoestemming | versie `0.05.14+10064`, 458 tests, productiepreflight en ondertekende `DragonHaven.apk` | De loadprofieltest leidt de actuele repositorymigratie nu correct af als 41 en de seasonal staging-E2E eist expliciet migraties 40 én 41. Analyzer, alle 458 tests, PowerShell-parse en levende-documentatiegates zijn groen. De APK heeft package `nl.dragonhaven.app`, Android-versionName `0.05.14`, versionCode `10064`, 477.701.825 bytes, SHA-256 `5d1bbd939e81665ccfd5904bfa55292f597456f2f6742a76d776c8ba38a8180f` en het vaste certificaat `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`; installatie als update op de open emulator is geslaagd. |
| 07-09-2026 | v0.05.14 openbaar en volledig groen | Codex, binnen jouw releasetoestemming | [release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.14), [taggate 34074223335](https://github.com/Rakky88/DragonHaven/actions/runs/34074223335), [healthrun 34074693676](https://github.com/Rakky88/DragonHaven/actions/runs/34074693676) en AAB-artifact `10001617610` | Exact commit `768a6ac48f681d3d9bea2ea63a6048bde4c453d2` is getagd en v0.05.14 is Latest. Remote `DragonHaven.apk` heeft exact de lokale grootte 477.701.825 bytes en SHA-256 `5d1bbd939e81665ccfd5904bfa55292f597456f2f6742a76d776c8ba38a8180f`; versiegebonden en permanente downloads geven HTTP 200. De taggate herhaalde productiepreflight, analyzer, 458 tests, vaste signing en Play-ready AAB volledig groen. De healthrun bevestigde Auth en applicatiehealth en opende geen storingsalert. Staging en productie blijven gezond op 41/41; de economyactivatie blijft uit. |

## Onderhoud van dit plan

Werk na iedere relevante release of audittranche minimaal de uitgangsversie,
gewogen percentages, checklisttellingen, eigenaar/overdracht, statusvakjes,
besluitenlog, voortgangslog en releasepoorten bij. Controleer ook of
`PUBLIC_LAUNCH.md`, `SERVER_IMPROVEMENTS.md`, `DISTRIBUTION.md` en de actuele
audit nog naar dezelfde werkelijkheid verwijzen. Geen afgevinkte taak mag alleen
op aannames rusten: voeg altijd een test, workflowrun, dashboard, migratiebewijs
of expliciet gebruikersbesluit toe. Codex is eigenaar van dit onderhoud na door
Codex uitgevoerd werk; Rick blijft eigenaar van externe accountacties en
productbesluiten en bevestigt wanneer die werkelijk zijn uitgevoerd.

| 07-09-2026 | v0.05.15 releasecandidate gecontroleerd | Codex, binnen jouw releasetoestemming | 467 tests, lokale productiepreflight en ondertekende APK | Friends/Conclave-tabs en lokale unread-badge, Witchlight-pompoenen/padtraceren, schonere Trial-rank en actieve avonturen op eindtijd. APK: 477.734.589 bytes, SHA-256 `1b9de0973d9de761d7486d95bf43240f78ad6a83dcc9a5b19d94920c4203d529`; package `nl.dragonhaven.app`, versionName `0.05.15`, versionCode `10065`; certificaat `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`. Preflight herhaald om 07:25 UTC: 41/41 migraties, nul lintfouten, Auth en apphealth HTTP 200. GitHub dry-run: tag en asset bestaan nog niet, geen vervanging nodig. |

| 07-09-2026 | v0.05.15 lokaal afgerond; publicatie wacht op expliciete bronuploadtoestemming | Codex | broncommit `b7d5584ec65225aa9be025bf04ad233b3b20a169`, releasebranch `release/v0.05.15` | De definitieve analyzer is schoon, 467 tests zijn groen en de definitieve APK is als update op emulator-5554 geinstalleerd met versionName 0.05.15/versionCode 10065. About toont v0.05.15; Friends/Conclave en het echte Trial-uitslagvenster zonder achtergrondsterren zijn visueel gecontroleerd. De eerste analyse na screenshots waarschuwde uitsluitend voor het tijdelijke reviewtestscript buiten test/; dit tijdelijke script is verwijderd en de eindanalyse is groen. De automatische goedkeuringscontrole blokkeerde de bron-/auditpush naar Rakky88/DragonHaven omdat de algemene releasetoestemming volgens de controle niet expliciet genoeg was voor deze bronupload. De push is niet uitgevoerd; er is geen v0.05.15-tag of release aangemaakt. Laatste openbare versie blijft v0.05.14. APK, signing, release-notes, read-only GitHub dry-run en productiepreflight zijn gereed. |

| 07-09-2026 | v0.05.15 publicatie hervat op uitdrukkelijk verzoek | Codex | opnieuw bevestigde releasetoestemming en productiepreflight om 07:33 UTC | De gebruiker heeft na de expliciete vraag om de bron-/auditupload en publicatie opnieuw opdracht gegeven de release uit te brengen. De ongewijzigde, gevalideerde APK blijft 477.734.589 bytes met dezelfde SHA-256. Productie is nog steeds 41/41 met nul lintfouten en HTTP 200 voor Auth en applicatiehealth. GitHub dry-run bevestigt dat v0.05.15 nog niet bestaat. Het Egg Altar blijft een lokaal ontwerp en maakt geen deel uit van deze release. |

| 07-09-2026 | v0.05.15 gepubliceerd en als Latest geverifieerd | Codex, op uitdrukkelijk verzoek | [release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.15), [APK](https://github.com/Rakky88/DragonHaven/releases/download/v0.05.15/DragonHaven.apk), [vaste download](https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk), [taggate 34096132993](https://github.com/Rakky88/DragonHaven/actions/runs/34096132993) | De release wijst exact naar commit `9f282216af6929a45d45ff37009a49e0642a08ef`. Asset `DragonHaven.apk` (ID 548376024) heeft exact 477.734.589 bytes en SHA-256 `1b9de0973d9de761d7486d95bf43240f78ad6a83dcc9a5b19d94920c4203d529`, gelijk aan de lokaal gecontroleerde APK. Latest is v0.05.15; beide downloadroutes geven HTTP 200. De onafhankelijke healthcheck na upload om 07:39 UTC bevestigt Auth health/settings en applicatiehealth HTTP 200. De taggate heeft productiepreflight, analyzer en tests groen afgerond; ook de aanvullende gesigneerde Play Store-bundle, artifactverificatie en volledige taggate zijn succesvol afgerond. Geen migraties of economyinstellingen gewijzigd. |
