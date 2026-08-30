# DragonHaven — uitbreidingsideeën en eerlijke monetisatie

Laatst bijgewerkt: **30 augustus 2026**
Uitgangsversie: **v0.04.13**

## Doel en uitgangspunten

Dit document verzamelt ideeën waarmee DragonHaven groter, gezelliger en langer
interessant kan worden, plus manieren om inkomsten te verdienen zonder
advertenties, pay-to-win of manipulatieve aankoopdruk.

DragonHaven heeft al een sterke basis: 42 publieke dragon families plus
geheime families, evoluties en Spectral-vormen, Adventures, Trials, Group
Adventures, Special Events, de Tower, furniture, Friends, trades, relics,
achievements, de Draconomicon en een uitgebreide Jukebox. De voorstellen
hieronder bouwen daarop voort en proberen bestaande systemen opnieuw te
gebruiken in plaats van telkens een los subsysteem toe te voegen.

De voorgestelde productbelofte is:

> Iedere speler kan alle gameplay, dragon families, evoluties, expertises en
> gewone events zonder betaling beleven. Betalen geeft expressie, extra
> verhalen of een manier om de ontwikkeling te steunen — nooit sterkere
> draken, betere kansen of minder verplichte wachttijd.

## Deel 1 — leuke uitbreidingen voor de game

### Overzicht en prioriteit

| # | Idee | Waarom het bij DragonHaven past | Omvang | Advies |
|---:|---|---|---|---|
| 1 | Family Chronicles | Geeft iedere dragon family eigen lore en emotionele momenten | Middel | **P1** |
| 2 | Keuze-Adventures | Maakt Adventures interactiever zonder gevechten toe te voegen | Groot | **P1** |
| 3 | Friend Tower Visits | Maakt Friends zichtbaar en persoonlijk | Groot | **P1** |
| 4 | Dragon Photo Mode | Benut alle bestaande sprites, kamers en achtergronden | Middel | **P1** |
| 5 | Seizoenskalender | Houdt bestaande Special Events vindbaar en voorspelbaar | Klein/middel | **P1** |
| 6 | Curator Collections | Geeft verzamelde dragons, furniture en muziek nieuwe doelen | Middel | **P1** |
| 7 | Duplicate Crafting | Maakt dubbele items nuttig zonder meer loot nodig te maken | Middel | **P1**, na economiehardening |
| 8 | Dragon Bonds | Laat draken onderling vriendschappen en voorkeuren ontwikkelen | Middel | **P2** |
| 9 | Haven Atlas | Verbindt Adventures en ontdekkingen aan een wereldkaart | Groot | **P2** |
| 10 | Sanctuary Biomes | Geeft volgroeide collecties een tweede gezellige verblijfplaats | Groot | **P2** |
| 11 | Blueprint Sharing | Laat spelers kamers delen zonder furniture weg te geven | Groot | **P2** |
| 12 | Adventure Postcards | Maakt Adventures ook visueel verzamelbaar | Middel | **P2** |
| 13 | Dragon School | Voegt rustige trainingsactiviteiten en nieuwe minigames toe | Groot | **P2** |
| 14 | Furniture Workshop | Geeft cosmetische kleur- en materiaalvarianten | Groot | **P2** |
| 15 | Community Constellations | Coöperatieve wereldwijde doelen zonder leaderboarddruk | Groot | **P3** |
| 16 | Keeper Journal | Maakt de persoonlijke geschiedenis van de save zichtbaar | Middel | **P2** |
| 17 | Weather & Soundscapes | Maakt de Tower levendiger met weinig nieuwe spelregels | Middel | **P2** |
| 18 | Music Rooms & Concerts | Geeft de Jukebox en verzamelde muziek een plek in de wereld | Middel | **P3** |
| 19 | Lore Research | Beloont collectiecombinaties met verhalen en illustraties | Middel | **P2** |
| 20 | Dream Portals | Tijdelijke surrealistische locaties met afwijkende presentatie | Groot | **P3** |
| 21 | Cozy Daily Omens | Een kleine dagelijkse verrassing zonder straf voor gemiste dagen | Klein | **P2** |
| 22 | Dragon Talent Festivals | Niet-competitieve shows rond karakter en uiterlijk | Groot | **P3** |
| 23 | Guestbook & Reactions | Veilige sociale waardering zonder vrije chat | Middel | **P2** |
| 24 | Collection Milestones 2.0 | Meer zichtbare langetermijndoelen per systeem | Klein/middel | **P1** |

### 1. Family Chronicles

Geef iedere dragon family een korte reeks van bijvoorbeeld drie tot vijf
hoofdstukken. Hoofdstukken worden ontgrendeld door natuurlijke momenten, zoals
uitkomen, Wyrmling worden, een bepaalde expertise halen, een favoriete kamer
vinden of Mastery bereiken.

- Gebruik korte geïllustreerde story cards en bestaande sprites.
- Laat keuzes vooral tekst, herinneringen of cosmetische details veranderen.
- Bewaar één Chronicle per familie in de Draconomicon.
- Geef bij voltooiing bijvoorbeeld een family banner, kamerornament of
  fotolijst; geen expertise- of snelheidsbonus.
- Begin met drie geliefde families als verticale proef voordat alle families
  content krijgen.

Dit is waarschijnlijk de beste combinatie van relatief beperkte techniek en
veel extra persoonlijkheid.

### 2. Keuze-Adventures

Laat sommige solo-Adventures één of twee gebeurtenissen bevatten waarop de
speler reageert. Bijvoorbeeld: een verdwaalde reiziger helpen, een onbekende
ruïne onderzoeken of voorzichtig terugkeren.

- Keuzes kunnen het verhaal, de ansichtkaart en de soort gewone reward
  beïnvloeden, maar niet zo sterk dat één keuze objectief verplicht wordt.
- Moral, Order en personality kunnen extra tekstopties geven zonder een
  “foute” dragon te creëren.
- De Adventure mag asynchroon blijven: de speler krijgt bij terugkomst de
  keuze-scène en daarna pas de reward.
- Special Adventures kunnen hiermee romantischer, grappiger of geheimzinniger
  worden zonder een nieuw eventframework te vereisen.

### 3. Friend Tower Visits

Laat spelers een read-only versie van de Tower van een vriend bekijken.

- Toon alleen door de eigenaar bewust gepubliceerde kamers en showcase-dragons.
- Bezoekers kunnen één vooraf bepaalde reactie achterlaten, zoals een hart,
  ster, vlam of maan; geen vrije tekst nodig.
- Er zijn geen bezoekrewards nodig. Daardoor ontstaat geen verplichte dagelijkse
  kliklus en geen mogelijkheid om accounts te farmen.
- De eigenaar kan bezoekers, reacties en publieke kamers volledig uitschakelen.
- Gebruik een gecachte, begrensde public snapshot in plaats van de volledige
  save. Dit hoort server-side en met Row Level Security te worden gebouwd.

### 4. Dragon Photo Mode

Een compositiescherm waarin de speler één tot drie eigen draken, een Tower-room
of eventachtergrond, een pose, kader en korte voorgeschreven tekst kan kiezen.

- Exporteer lokaal als afbeelding; upload standaard niets.
- Bied veilige uitsneden voor telefoonachtergrond, profielfoto en deelkaart.
- Laat Spectral, favoriete en relic-iconen optioneel zichtbaar zijn.
- Voeg verzamelbare poses en kaders toe als achievement- of eventrewards.
- Dit is ook een natuurlijke, eerlijke plek voor betaalde cosmetische packs.

### 5. Seizoenskalender en Event Archive

Toon in de app een kalender met aangekondigde, actieve en eerder beleefde
Special Events.

- Verborgen events kunnen alleen een vaag silhouet of “A surprise approaches”
  tonen.
- Een voltooid event krijgt verhaal, rewards en herinneringsillustraties in een
  archief.
- Terugkerende events tonen de volgende bekende datum in lokale tijd.
- Een event dat al gestart is blijft volgens de bestaande regels afmaakbaar.
- Dit benut het bestaande datagedreven Special Adventure-framework.

### 6. Curator Collections

Voeg tijdelijke of permanente tentoonstellingsopdrachten toe, bijvoorbeeld
“drie waterachtige families”, “een blauwe kamer met maanlicht” of “een
Debussy-afspeellijst”.

- Een opdracht controleert alleen bezit of een opgeslagen compositie; items
  worden niet verbruikt.
- Spelers mogen meerdere geldige oplossingen gebruiken.
- Rewards zijn badges, kaders, titles, lorepagina's of furniturevarianten.
- Geen dagelijkse vervaldwang: geef opdrachten meerdere weken of laat ze
  permanent terugkomen.

### 7. Duplicate Crafting

Maak dubbele tradeable furniture of andere daarvoor aangewezen cosmetica nuttig
door ze te ontleden tot bijvoorbeeld **Stardust**.

- Stardust koopt alleen gerichte cosmetische varianten of ontbrekende gewone
  decoratie; geen dragons, expertise, relics of incubatiesnelheid.
- Toon vóór ontleden exact wat verdwijnt en wat de speler krijgt.
- Favoriete, geplaatste, gereserveerde en in-trade zijnde items zijn beschermd.
- De server moet de transactie atomair verwerken voordat dit online of met
  betaalde goederen wordt gecombineerd.

### 8. Dragon Bonds

Draken die vaak dezelfde kamer delen of samen Group Adventures doen kunnen een
vriendschapsband opbouwen.

- Bonds ontgrendelen korte ambient animaties, sayings, duo-foto’s en kleine
  verhalen.
- Geen expertise- of rewardmultipliers: een bond is karakterontwikkeling, geen
  optimale teamstatistiek.
- De speler kan een paar “beste vrienden” vastpinnen zonder andere banden te
  verwijderen.
- Vrijlaten of traden krijgt een duidelijke waarschuwing als een zichtbare bond
  bestaat.

### 9. Haven Atlas

Maak een geïllustreerde wereldkaart waarop Adventure-locaties langzaam worden
ontdekt.

- Bestaande Adventure-definities krijgen een regio, herkenningspunt en korte
  loretekst.
- Voltooide Adventures kleuren routes of landmarks in.
- Special Events kunnen tijdelijk een eiland, poort of sterrenbeeld toevoegen.
- De kaart geeft verzamelvoortgang, geen travel energy of betaalde toegang.

### 10. Sanctuary Biomes

Naast de Tower kan de speler rustige buitengebieden ontgrendelen, zoals een
maanweide, wolkenarchipel, oerbos of vulkanische grot.

- Draken bezoeken het Sanctuary automatisch en blijven altijd beschikbaar voor
  Adventures tenzij ze werkelijk op pad zijn.
- Biomes gebruiken voorkeuren, form, rarity en personality voor ambient
  gedrag, niet voor productiebonussen.
- Decorations kunnen tussen Tower en Sanctuary verschillende presentaties
  hebben zonder dubbel bezit te eisen.

### 11. Blueprint Sharing

Spelers kunnen een kamersetup als read-only blueprint delen.

- Een blueprint kopieert posities en item-ID's, niet de items zelf.
- De ontvanger ziet welke furniture al bezit is en kan een gedeeltelijke versie
  plaatsen.
- Gebruik Keeper ID of een korte servercode; geen willekeurige externe links.
- Laat naamgeving kiezen uit veilige vaste woorden of modereer vrije namen.

### 12. Adventure Postcards

Een klein deel van Adventures levert een illustratieve postcard op met datum,
dragon, locatie en één zin uit het avontuur.

- Postcards zijn een collectie los van economische rewards.
- Dezelfde kaart kan een ander weer-, dagdeel- of Spectral-accent krijgen.
- Favoriete kaarten kunnen in Tower-frames worden geplaatst of in Photo Mode
  worden gebruikt.
- Dubbele kaarten hoeven niet te bestaan: ontdekt is ontdekt.

### 13. Dragon School

Een roterende selectie rustige oefeningen naast de huidige Might, Arcana en
Spirit Trials.

- Denk aan patroonherkenning, ritme, een korte vliegroute, voorwerpen sorteren
  of een geheugenactiviteit.
- Scores leveren persoonlijke records, animation badges of poses op.
- Geen wereldwijde ranglijst en geen betaalde extra pogingen.
- Houd reduced motion, grote tekst, kleurcontrast en alternatieve input vanaf
  het ontwerp in beeld.

### 14. Furniture Workshop

Laat furniture cosmetisch aanpassen met kleurpaletten, houtsoorten, stoffen of
lichteffecten.

- Het basisitem blijft herkenbaar en iedere variant blijft even functioneel.
- Paletten komen uit gameplay, achievements, events en directe cosmetische
  packs.
- Een preview laat de room overdag en ’s nachts zien voordat iets wordt
  toegepast.
- Sla een variantrecept op in plaats van voor iedere combinatie een nieuw groot
  rasterbestand te maken waar dat visueel verantwoord is.

### 15. Community Constellations

Alle spelers dragen gedurende een event bij aan één gezamenlijk doel, zoals
voltooide Adventures of gemaakte foto’s.

- Iedere geldige bijdrage telt, maar persoonlijke rewards zijn bij een lage,
  begrensde eigen bijdrage al compleet.
- Geen top-100 of exclusieve winnaar; de gemeenschap ontgrendelt samen een
  illustratie, muziekstuk of terugkerend event.
- Toon afgeronde mijlpalen ook als het einddoel niet wordt gehaald.
- Servervalidatie en rate limiting zijn noodzakelijk voordat dit live gaat.

### 16. Keeper Journal

Maak een chronologische geschiedenis van bijzondere momenten:

- eerste hatch, eerste Spectral, iedere evolutie en Mastery;
- zeldzame Adventure- of returning-dragon-momenten;
- achievements, favoriete foto’s en Special Events;
- vriendschappen en gezamenlijke Group Adventures zonder gevoelige details.

De journal werkt goed als persoonlijke terugblik en maakt een jarenoude save
waardevol zonder een powercurve toe te voegen.

### 17. Weather & Soundscapes

Voeg regen, mist, sneeuw, vallende sterren en warme zomernachten toe aan Tower
en Sanctuary.

- Weer is lokaal cosmetisch en hoeft niet van echt weer of locatiepermissie af
  te hangen.
- Gebruik de bestaande tijdsfases en audiofades.
- Geef aparte toggles voor weather effects, ambient sound en flitsen.
- Special Events kunnen een eigen weersprofiel activeren.

### 18. Music Rooms & Concerts

Laat een kamer als muziekruimte functioneren waar aanwezige draken subtiel op
het actieve Jukeboxnummer reageren.

- Een display toont componist, titel en verworven bron.
- Spelers kunnen een afspeellijst aan een kamer koppelen.
- Kleine concertmomenten gebruiken alleen nummers waarvan opname en compositie
  aantoonbaar correct gelicenseerd zijn.
- Cosmetics zoals lessenaars, grammofoons en podiumlichten passen hier goed.

### 19. Lore Research

Ontgrendel lorepagina’s door betekenisvolle combinaties in de collectie, zoals
meerdere forms van één familie, verwante biomes of drie Mastery-dragons.

- Research kost geen valuta en heeft geen wachttimer.
- De reward is kennis: illustraties, uitspraken, historische kaarten en
  silhouetten van toekomstige geheimen.
- Dit geeft de Draconomicon meer diepte zonder de hatchkansen te wijzigen.

### 20. Dream Portals

Af en toe verschijnt een droompoort met een korte, surrealistische scène.

- De speler kiest één eigen dragon en beleeft vijf tot tien minuten verhaal of
  een bijzondere minigame.
- De droom kan visueel afwijken zonder de vaste wereldlore te beschadigen.
- Voltooiing geeft een herinnering, achtergrond of fotokader.
- Portals kunnen later als eventformat worden hergebruikt.

### 21. Cozy Daily Omens

Eenmaal per lokale dag verschijnt een kleine voorspelling, uitspraak of
observatie van een aanwezige dragon.

- Geen streak, gemiste-dagstraf of oplopende “kom morgen terug”-beloning.
- Sommige omens verwijzen naar weer, muziek, een favoriete room of een naderend
  event.
- De speler kan bijzondere omens in de Keeper Journal bewaren.

### 22. Dragon Talent Festivals

Een periodieke show waarin de speler een dragon presenteert rond thema’s als
“meest mysterieuze pose” of “gezelligste winterkamer”.

- Beoordeling is persoonlijk of coöperatief, niet competitief.
- Iedere inzending voltooit het event; variatie komt uit presentatie en verhaal.
- Friends kunnen vaste positieve reacties geven, maar bepalen geen exclusieve
  reward.

### 23. Guestbook & veilige reacties

Koppel aan Tower Visits een klein guestbook met vooraf vertaalde reacties.

- De eigenaar kan reacties uitschakelen, verwijderen of alleen van Friends
  toestaan.
- Geen vrije chat, afbeeldingen van anderen of externe links.
- Rate limits, block/report en server-side eigenaarscontrole blijven nodig.

### 24. Collection Milestones 2.0

Maak voor elk groot systeem een duidelijke, niet-verlopende milestonepagina:

- forms en families per rarity;
- Spectral-collectie;
- Chronicle- en lorevoortgang;
- furniture themes en ingerichte kamers;
- muziek, portraits, titles, postcards en achievements.

Milestones geven vooral badges, banners en accountpresentatie. Ze mogen nooit
een betaalde collectie vereisen om de gewone 100%-status te halen.

## Aanbevolen bouwvolgorde

### Tranche A — veel waarde, weinig nieuwe serverrisico’s

1. Seizoenskalender en Event Archive.
2. Collection Milestones 2.0.
3. Eerste drie Family Chronicles.
4. Dragon Photo Mode met alleen lokale export.
5. Keeper Journal en Adventure Postcards.

### Tranche B — meer diepte in bestaande loops

1. Curator Collections.
2. Keuze-Adventures.
3. Dragon Bonds.
4. Weather & Soundscapes.
5. Lore Research.

### Tranche C — server en sociale systemen

1. Read-only Friend Tower snapshots.
2. Guestbook met vaste reacties en block/report.
3. Blueprint Sharing.
4. Duplicate Crafting als atomaire servermutatie.
5. Community Constellations met rate limiting.

### Tranche D — grote nieuwe werelden

1. Haven Atlas.
2. Sanctuary Biomes.
3. Dragon School.
4. Furniture Workshop.
5. Dream Portals en Talent Festivals.

## Deel 2 — monetisatie zonder advertenties of pay-to-win

### Wat “niet pay-to-win” voor DragonHaven concreet betekent

DragonHaven heeft geen PvP, maar betalen kan nog steeds oneerlijk voelen als
het een dragon sneller laat uitkomen, meer expertise geeft, hogere rarity-odds
oplevert of gratis spelers structureel achter laat lopen. Daarom gelden deze
grenzen:

- Geen betaalde expertise, XP, Ascension, extra Trial-pogingen of betere scores.
- Geen betaalde incubatieverkorting, Adventure-versnelling of extra actieve
  slots.
- Geen drakenfamilies, forms, Spectral-kansen of Mastery achter echt geld.
- Geen betaalde relics of andere items die gameplay beïnvloeden.
- Geen willekeurige betaalde chests, eggs, wheels of “mystery packs”.
- Geen VIP-odds, pityvoordeel of betaalde returning-dragon-kansen.
- Geen beperkte voorraad, kunstmatige countdowns of nep-kortingen.
- Geen verloren dagelijkse streak als drukmiddel.
- Iedere aankoop toont vooraf exact wat permanent wordt verkregen.
- Een gratis speler behoudt een complete, prettige kernervaring.

### Belangrijke keuze rond de huidige coins en gems

De huidige geplande europrijsladder voor coin- en gempacks is technisch al in
de code voorbereid, maar activering ervan past **niet automatisch** bij deze
eerlijke productbelofte. Coins en gems kunnen nu onder andere kisten,
furniture en relic-gerelateerde voortgang raken. Verkoop daarvan kan daarom
als pay-to-progress voelen en betaalde gems kunnen indirect bij willekeurige
chestinhoud uitkomen.

Aanbeveling:

1. Activeer verkoop van de bestaande coins en gems voorlopig niet.
2. Houd verdiende coins/gems gameplay-only.
3. Verkoop directe, bekende cosmetische entitlements via Google Play.
4. Als een betaalvaluta voor meerdere cosmetics echt gewenst is, maak later een
   aparte **cosmetic-only** valuta die nooit naar gameplayvaluta kan worden
   omgezet en niets willekeurigs koopt. Directe aankopen blijven transparanter.

### Goede verdienmodellen

| # | Verdienmodel | Wat de speler precies koopt | Eerlijkheidsniveau | Wanneer |
|---:|---|---|---|---|
| 1 | Supporter Pack | Badge, title, portrait, frame en decoratie | Zeer hoog | **Als eerste** |
| 2 | Directe room theme packs | Bekende set furniture/walls/floor/lighting | Zeer hoog | Vroeg |
| 3 | Dragon cosmetic packs | Aura, naamplaatje, voetspoor of fotopose | Hoog | Vroeg/middel |
| 4 | Photo Mode packs | Kaders, achtergronden, stickers en poses | Zeer hoog | Na Photo Mode |
| 5 | Keeper identity packs | Vooraf zichtbare portraits, titles en profielkaders | Zeer hoog | Vroeg |
| 6 | Premium side stories | Afgerond zijverhaal met cosmetische rewards | Hoog | Na Chronicles |
| 7 | Permanente event journeys | Niet-verlopende cosmetische rewardroute | Hoog | Middel |
| 8 | Event Archive expansions | Oude extra verhaalhoofdstukken permanent speelbaar | Hoog | Middel |
| 9 | Digital artbook/lorebook | Illustraties, concept art en developer notes | Zeer hoog | Middel |
| 10 | Support tiers/tip products | Transparante eenmalige steun met hetzelfde bedankje | Zeer hoog | Vroeg |
| 11 | Haven Patron-abonnement | Doorlopende maandelijkse cosmetics en making-of | Hoog, mits echt doorlopend | Pas later |
| 12 | Soundscape packs | Direct gekozen ambient themes met juiste licenties | Zeer hoog | Middel |
| 13 | Blueprint creator pack | Extra cosmetische labels, covers en layoutsaves | Hoog | Na sharing |
| 14 | Grote uitbreidingsbundel | Nieuwe biome/verhaalcampagne, geen exclusieve power | Hoog | Laat |
| 15 | Fysieke merchandise | Prints, artbook, pins of plushies buiten gameplay | Zeer hoog | Pas bij publiek |

### 1. Eenmalig Supporter Pack

Een niet-verbruikbare aankoop, bijvoorbeeld **Keeper’s Supporter Pack**, met:

- één duidelijk gemarkeerde supporter title;
- één portrait en profielkader;
- één Tower-banner of standbeeld;
- enkele Photo Mode-kaders;
- een bedankpagina in de credits.

Alle inhoud staat vooraf in beeld. Het pack geeft geen valuta, chest, egg,
relic of tijdsvoordeel. Een prijsgebied van bijvoorbeeld €2,99–€6,99 kan later
in Play Console per markt worden gelokaliseerd; de app toont altijd de echte
Play-prijs.

### 2. Directe room theme packs

Verkoop complete, bekende decoratiesets zoals Celestial Library, Cozy Bakery,
Moonlit Conservatory of Dragon Nursery.

- Laat ieder onderdeel vooraf in dag- en nachtpreview zien.
- Een gekocht pack is accountbreed en herstelbaar.
- Gratis events en coins blijven ook volwaardige furniture opleveren.
- Geen room geeft productie- of dragonbonussen.

### 3. Dragon cosmetics zonder stats

Geschikte cosmetica zijn aura’s, kleine naamplaatjes, footprints, fotoposes,
slaapeffecten of een decoratief lint bij de kaart van een dragon.

- Verander nooit silhouette of leesbaarheid van de officiële form-sprite.
- Geen cosmetic heeft een expertise-, XP- of rewardeffect.
- Bied een duidelijke preview op meerdere forms en achtergronden.
- Maak cosmetics unequipable en vrij wisselbaar.

### 4. Photo Mode creator packs

Photo Mode kan zichzelf eerlijk financieren met thema-achtergronden, kaders,
veilige stickers, belichting en compositielayouts.

- Lokale export en de basiscamera blijven gratis.
- Een pack bevat een vaste lijst; niets wordt gerold.
- Aankopen beïnvloeden Draconomicon- of achievementpercentages niet.

### 5. Keeper identity packs

Verkoop kleine bundels met vooraf zichtbare portraits, account titles,
nameplate-stijlen en profielachtergronden.

- Houd betaalde cosmetics in een aparte categorie van de 100 Portrait- en 500
  Title-collecties, zodat “alles verzameld” gratis haalbaar blijft.
- Betaalde items komen niet uit Portrait/Title Chests en tellen niet voor hun
  odds of capaciteit.

### 6. Premium zijverhalen

Een betaalde Chronicle-bundel kan drie tot vijf volledig geschreven
zijverhalen bevatten, met vaste cosmetische rewards.

- Alle gewone families en evoluties blijven gratis.
- Verhalen leveren geen exclusieve gameplaykennis die nodig is voor progressie.
- Maak vooraf lengte, inhoud en rewards duidelijk.
- Een goede bundel is permanent herspeelbaar en werkt offline nadat de
  entitlement is gesynchroniseerd.

### 7. Permanente event journeys

Een alternatief voor een klassieke battle pass: een betaalde cosmetische route
zonder einddatum. De speler koopt bijvoorbeeld **Moon Festival Journal** en
ontgrendelt de inhoud in eigen tempo door gewone activiteiten.

- Geen dagelijkse opdrachten of vervaldatum.
- Geen betaalde XP-booster voor de route.
- Het gratis event en de eventdragon blijven volledig beschikbaar.
- Toon alle stappen en cosmetics vooraf.

Dit voorkomt FOMO en is veel beter passend bij een rustige game.

### 8. Event Archive expansions

Na een gratis Special Event kan later een extra, permanent verhaalhoofdstuk in
het archief worden verkocht.

- Het oorspronkelijke event, achievement en de dragon blijven gratis.
- De uitbreiding geeft extra verhaal, foto-achtergronden en roomdecoratie.
- Geen gemiste eventreward wordt tegen betaling “gerepareerd”.

### 9. Digitaal artbook of lorebook

Een in-app artbook met concept art, sprite-ontwikkeling, lore, muziekcredits en
developer notes is een transparante eenmalige aankoop.

- Controleer per afbeelding en opname dat DragonHaven die commercieel mag
  distribueren.
- Maak tekst schaalbaar en exporteer geen bronbestanden die niet voor
  herdistributie bedoeld zijn.
- Een kleine gratis preview helpt de speler begrijpen wat wordt gekocht.

### 10. Vrijwillige supportproducten

Bied bijvoorbeeld drie eenmalige steunbedragen aan. Ieder bedrag geeft
dezelfde kleine bedankbadge; de hogere prijs koopt bewust geen betere status.

- Gebruik voor digitale steun in een Play-app de geldende Play-betaalroute.
- Noem het geen goed doel of donatie tenzij de juridische voorwaarden daarvoor
  werkelijk zijn vervuld.
- Verberg de knop niet achter verlies, foutmeldingen of dagelijkse prompts.

### 11. Haven Patron-abonnement — alleen later

Een abonnement kan eerlijk zijn als DragonHaven aantoonbaar iedere maand nieuwe
doorlopende waarde kan leveren, bijvoorbeeld:

- een maandelijkse cosmetic set;
- making-of, concept art en een developer diary;
- extra Photo Mode-content;
- vroegtijdige preview, maar geen exclusieve gameplay of betere odds.

Dit is **niet** geschikt voor de eerste monetisatiefase. Een abonnement vraagt
een betrouwbare contentkalender, support, heldere opzegging en blijvende waarde.
Google Play verlangt dat subscriptions transparant zijn en duurzame,
terugkerende waarde bieden; een eenmalige stapel gems hoort dus geen abonnement
te zijn.

### 12. Soundscape packs

Verkoop rechtstreeks gekozen ambient packs, bijvoorbeeld Forest Rain, Cosmic
Observatory of Winter Hearth.

- Gebruik alleen eigen, CC0/Public Domain of aantoonbaar commercieel
  gelicenseerde **opnames**; een publiek-domeincompositie maakt niet iedere
  moderne opname rechtenvrij.
- De bestaande Jukebox en basisachtergrondmuziek blijven gratis.
- Een preview mag kort en lokaal zijn zonder het hele bestand apart vrij te
  geven.

### 13. Blueprint creator pack

Na introductie van Blueprint Sharing kan een creator pack extra coverstyles,
presentatielabels en lokale opgeslagen layouts geven.

- Gratis spelers kunnen blueprints blijven maken, delen en gebruiken.
- Het pack verhoogt geen inventorycapaciteit en kopieert geen betaalde
  furniture naar anderen.

### 14. Grote betaalde uitbreiding

Pas wanneer de gratis game inhoudelijk volwassen is, kan een grote uitbreiding
een nieuwe biome, verhaalcampagne, soundscape en furniturethema bundelen.

- Geen exclusieve dragon family die nodig is voor de hoofddraconomicon.
- Geen verhoogde level cap of sterkere expertise.
- De uitbreiding is een vaste, permanente aankoop en geen losse microreeks.

### 15. Fysieke merchandise

Bij voldoende publiek kunnen artprints, pins, een fysiek artbook of plushies
inkomsten geven zonder de spelbalans te raken.

- Begin eventueel met print-on-demand om voorraadrisico te beperken.
- Gebruik een duidelijke externe winkel en eigen retour-/privacyvoorwaarden.
- Geef hooguit een gewone bedankbadge; geen exclusieve gameplaycode.
- Controleer merk-, productveiligheids-, btw- en consumentenregels voordat dit
  live gaat.

## Wat DragonHaven beter niet monetiseert

| Niet doen | Waarom |
|---|---|
| Coins/gems verkopen terwijl ze progressie of random chests kopen | Wordt pay-to-progress en koppelt echt geld indirect aan kansrollen |
| Betaalde incubatie- of Adventure-skips | Verandert bewust ontworpen tijd in verkoopdruk |
| Extra betaalde Trial-pogingen | Maakt records en rewards afhankelijk van besteding |
| Betaalde expertise/XP of dubbel-XP-items | Maakt dragonontwikkeling ongelijk |
| Betaalde relics | Relics veranderen gameplay en ontdekkingen |
| Exclusieve betaalde dragon families/forms | Vergrendelt de kern van het verzamelspel |
| Random betaalde chests/eggs | Minder transparant, gevoelig voor gokachtige druk en oddsregels |
| Verlopende battle pass | Creëert FOMO en verplicht speeltempo |
| VIP-tier met betere odds | Rechtstreeks pay-to-win/pay-to-progress |
| Energie die alleen met geld snel herstelt | Maakt stoppen met spelen onderdeel van het verkoopmodel |
| Inventoryruimte als terugkerend betaalprobleem | Verkoopt de oplossing voor kunstmatig veroorzaakte frustratie |
| Pop-ups na verlies of mislukking | Benut kwetsbare emotionele momenten |
| Alleen betaalde cloudback-up | Basisveiligheid van voortgang hoort geen luxe te zijn |
| Betaalde verwijdering van notificaties of beperkingen | Basisprivacy en toegankelijkheid blijven gratis |

## Aanbevolen concrete startmix

Voor DragonHaven past deze combinatie het best:

1. **Gratis kernspel:** alle dragons, forms, expertises, Adventures, Trials,
   Friends en gewone events.
2. **Supporter Pack:** één vaste aankoop met bekende account- en Towercosmetics.
3. **Room theme packs:** directe vaste decoratiesets.
4. **Photo/identity packs:** kaders, poses, portraits en titles buiten de
   gratis collection counters.
5. **Premium Chronicles:** later optionele zijverhalen met alleen cosmetische
   rewards.
6. **Geen abonnement bij lancering.** Pas toevoegen als iedere maand echte,
   volhoudbare content beschikbaar is.
7. **Geen verkoop van huidige coins/gems bij lancering.** Eerst de economische
   servergrens afronden en daarna opnieuw toetsen of verkoop nog bij de belofte
   past.

## Voorbeeld van een eenvoudige productcatalogus

Dit zijn denkrichtingen, geen definitieve prijzen. Google Play moet uiteindelijk
de echte gelokaliseerde prijs leveren.

| Product | Type | Voorbeeldinhoud | Indicatief prijsgebied |
|---|---|---|---:|
| Keeper’s Supporter Pack | Eenmalig, non-consumable | Badge, title, portrait, frame, banner | €3,99–€6,99 |
| Celestial Library Theme | Eenmalig, non-consumable | Volledige vaste roomset | €2,99–€5,99 |
| Moonlit Photo Pack | Eenmalig, non-consumable | 8 kaders, 4 poses, 6 achtergronden | €1,99–€3,99 |
| Family Chronicle Bundle I | Eenmalig, non-consumable | 3–5 zijverhalen en vaste cosmetics | €3,99–€7,99 |
| Moon Festival Journal | Eenmalig, permanent traject | Zichtbare cosmetische rewardroute | €4,99–€8,99 |
| Digital DragonHaven Artbook | Eenmalig, non-consumable | Concept art, lore en making-of | €4,99–€9,99 |
| Support DragonHaven I/II/III | Eenmalig | Hetzelfde kleine dankteken | €0,99/€2,99/€5,99 |

## Rekenmodel voor opbrengst

Gebruik voor planning een eenvoudig model:

`bruto maandopbrengst = maandactieve spelers × koperspercentage × gemiddelde besteding per koper`

Voorbeelden, uitsluitend om de rekensom te tonen:

| MAU | Kopers | Gemiddeld per koper | Bruto vóór storefee, btw, refunds en kosten |
|---:|---:|---:|---:|
| 1.000 | 2% | €4 | €80/maand |
| 10.000 | 3% | €6 | €1.800/maand |
| 100.000 | 4% | €8 | €32.000/maand |

Dit zijn geen voorspellingen. Retentie, landenmix, prijs, contentkwaliteit,
storefees, btw, refunds, support en platformkosten kunnen het nettoresultaat
sterk veranderen. Google Play wijzigt zijn feeprogramma’s en regionale opties;
bouw daarom geen businesscase rond één eeuwig vast percentage.

## Technische voorwaarden voordat echt geld wordt geactiveerd

De huidige `PurchaseProvider` is bewust uitgeschakeld en legt al een goede grens
vast: de Flutter-client mag zichzelf nooit coins, gems of een entitlement geven
omdat een callback “success” zegt. Voor live aankopen is minimaal nodig:

1. Maak stabiele Play-product-ID’s voor consumables, non-consumables en pas veel
   later eventueel subscriptions.
2. Toon altijd de door Google Play geretourneerde gelokaliseerde prijs; zet geen
   hardcoded europrijs in de live aankoopknop.
3. Stuur het purchase token via TLS naar een beveiligde backend; log het token
   niet en bewaar het nooit in diagnostiek.
4. Verifieer product, package, accountkoppeling en status server-side.
5. Geef alleen iets wanneer de aankoop werkelijk `PURCHASED` is, nooit bij
   `PENDING`.
6. Schrijf iedere entitlement idempotent naar een serverledger, zodat retries
   geen dubbele inhoud geven.
7. Acknowledge of consume pas volgens het producttype nadat levering veilig is
   verwerkt. Niet tijdig acknowledge-en kan tot automatische refund leiden.
8. Reconcile aankopen bij login/foreground en verwerk refunds, revocations en
   aankopen vanaf een ander toestel.
9. Bouw een zichtbare **Restore purchases**-route voor non-consumables.
10. Houd betaalde cosmetics buiten gewone random chestpools, trades en
    gratis collection caps tenzij dat vooraf heel bewust anders wordt besloten.
11. Test pending, cancellation, timeout, dubbele callback, reinstall,
    multi-device, accountwissel, refund en offline herstel.
12. Voltooi eerst de server-authoritative economische basis uit
    `DRAGONHAVEN_POST_AUDIT_PLAN.md` voordat gekochte waarde aan de huidige
    inventory wordt gekoppeld.

## Actuele Play Store-aandachtspunten

Gecontroleerd op 30 augustus 2026; beleid kan wijzigen en moet vlak vóór
publicatie opnieuw worden gecontroleerd.

- Digitale goederen en functies in een via Play verspreide app moeten in de
  normale situatie via de toegestane Google Play-betaalroute lopen. Zie
  [Google Play Payments policy](https://support.google.com/googleplay/android-developer/answer/9858738).
- Als een aankoop willekeurige virtuele items kan opleveren, moeten de odds
  vooraf en vlak bij de aankoop duidelijk worden getoond. DragonHaven kan dit
  risico beter helemaal vermijden door geen betaalde random chests aan te
  bieden.
- Subscriptions moeten duidelijke prijs-, looptijd- en verlengingsinformatie en
  echte duurzame waarde bieden. Zie
  [Google Play Subscriptions policy](https://support.google.com/googleplay/android-developer/answer/9900533).
- Google adviseert aankoopverificatie en entitlementverlening via een veilige
  backend. Zie
  [Play Billing integreren](https://developer.android.com/google/play/billing/integrate)
  en
  [Play Billing backend-integratie](https://developer.android.com/google/play/billing/backend).
- Servicefees en regionale programma’s veranderen. Controleer vlak vóór
  prijsbesluiten de actuele
  [Google Play servicefees](https://support.google.com/googleplay/android-developer/answer/112622).

## Besluiten die later door de eigenaar nodig zijn

- Welke gratis kernbelofte letterlijk in store en app wordt vastgelegd.
- Of bestaande coins/gems definitief gameplay-only blijven.
- Welke drie eerste cosmetic packs worden gemaakt en wat ze kosten.
- Of betaalde cosmetics meetellen in aparte of totale collection counters.
- Welke leeftijdsdoelgroep en landen worden gekozen.
- Wie refunds, aankoopproblemen en accountrecovery behandelt.
- Wanneer Play Console, merchantprofiel, belasting- en uitbetalingsgegevens
  klaar zijn.
- Of een abonnement ooit wenselijk is en of de contentproductie dat werkelijk
  iedere maand kan waarmaken.

## Samenvattend advies

De sterkste uitbreidingsrichting is **meer betekenis geven aan wat spelers al
verzamelen**: Family Chronicles, Photo Mode, een Keeper Journal, Curator
Collections en Friend Tower Visits. Die systemen versterken de emotionele band
met draken zonder een steeds hogere stat- of raritycurve te vereisen.

De eerlijkste inkomstenmix is **direct verkochte cosmetics + permanente
zijverhalen + een transparant Supporter Pack**. Houd dragons, evoluties,
expertise, relics, timers en random chests volledig buiten echt geld. Daarmee
kan DragonHaven inkomsten verdienen zonder zijn rustige karakter of het
vertrouwen van gratis spelers op te offeren.
