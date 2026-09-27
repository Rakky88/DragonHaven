# Relieken in DragonHaven

Deze gids beschrijft alle relieken die in de huidige game bestaan, wat ze doen
en hoe je ze kunt krijgen. Er zijn **11 Mystic Relics** en **5 apart gemaakte
Egg Altar Relics**. `Astral Lens` bestaat in beide systemen als een apart
voorwerp. Daardoor zijn er 16 voorwerpen, maar 15 unieke namen.

## Mystic Relics

| Engelse naam in de game | Nederlandse naam | Type en gewicht | Effect | Manieren om hem te krijgen |
|---|---|---:|---|---|
| Moral Prism | Moreel Prisma | Verbruiksvoorwerp, 10 | Onthult of een draak Good, Neutral of Evil is. | Relic-drop; Gem Shop voor 500 gems; ruil van een gameplay-exemplaar. |
| Order Compass | Ordekompas | Verbruiksvoorwerp, 10 | Onthult of een draak Lawful, Neutral of Chaotic is. | Relic-drop; Gem Shop voor 500 gems; ruil van een gameplay-exemplaar. |
| Soul Mirror | Zielenspiegel | Verbruiksvoorwerp, 10 | Onthult de verborgen karaktereigenschappen van een draak. | Relic-drop; Gem Shop voor 500 gems; ruil van een gameplay-exemplaar. |
| Astral Lens | Astrale Lens | Verbruiksvoorwerp, 10 | Onthult de zeldzaamheid van een nog niet uitgekomen ei. | Relic-drop; Gem Shop voor 500 gems; ruil van een gameplay-exemplaar. |
| Chronoshard | Chronoscherf | Verbruiksvoorwerp, 10 | Verkort de resterende broedtijd in het nest met zijn opgeslagen percentage. | Relic-drop of ruil van een gameplay-exemplaar. |
| Wayfinder Sigil | Padvinderszegel | Verbruiksvoorwerp, 10 | Vervangt een gekozen Mini-, Short- of Long Adventure, of vult een vrije plek van het gekozen type. | Relic-drop of ruil van een gameplay-exemplaar. |
| Spark Astrolabe | Vonkastrolabium | Verbruiksvoorwerp, 1 | Onthult de permanente Dragon Spark van een draak: 0–50 extra totale expertise-capaciteit. | Alleen relic-drops; niet koopbaar, maakbaar of ruilbaar. Kan vaker worden gevonden. |
| Twinstar Brooch | Tweesterbroche | Permanent uitrustbaar, 1 | Verdubbelt alle XP voor de draak die hem draagt. | Alleen relic-drops; één keer per account en niet ruilbaar. |
| Emberheart Brooch | Gloeihartbroche | Permanent uitrustbaar, 1 | Verdubbelt de Might die de drager verdient in Adventures en Trials. | Alleen relic-drops; één keer per account en niet ruilbaar. |
| Moonweave Brooch | Maanweefbroche | Permanent uitrustbaar, 1 | Verdubbelt de Arcana die de drager verdient in Adventures en Trials. | Alleen relic-drops; één keer per account en niet ruilbaar. |
| Soulbloom Brooch | Zielenbloembroche | Permanent uitrustbaar, 1 | Verdubbelt de Spirit die de drager verdient in Adventures en Trials. | Alleen relic-drops; één keer per account en niet ruilbaar. |

Een informatie-reliek wordt niet verbruikt wanneer de gekozen informatie al
bekend is. Per draak kan maar één broche tegelijk zijn uitgerust. Een vervangen
broche blijft eigendom en wordt alleen unequipped. De expertise-broches
verdubbelen alleen werkelijk verdiende punten binnen de resterende gezamenlijke
expertise-capaciteit; zij verdubbelen geen Trial-score of chest-kans.

De Dragon Spark wordt één keer uit het vaste hatch seed bepaald. Iedere waarde
van 0 tot en met 50 heeft kans **1/51**. Een Spark Astrolabe onthult die waarde
en rerollt hem nooit.

Een nieuwe Chronoshard krijgt uniform een heel percentage van 10% tot en met
90%: ieder percentage heeft kans **1/81**. Bij een ruil blijft exact dat
percentage behouden. Als er meer dan één seconde resteert, wordt de nieuwe
resterende broedtijd op minimaal één seconde begrensd.

Een Wayfinder Sigil kiest uniform uit de geldige Adventures van het door de
speler gekozen type. Een route is alleen geldig wanneer hij niet al wordt
aangeboden, niet de vervangen route is en niet actief wordt gespeeld. De Sigil
wordt niet verbruikt wanneer er geen geldige wijziging kan worden gemaakt.

## De gewogen relic-pool

Een nieuwe account heeft aanvankelijk **65 tickets** in de pool:

- zes gewone Mystic Relics met elk 10 tickets: 60 tickets;
- Spark Astrolabe met 1 ticket;
- vier broches met elk 1 ticket.

De vier broches zijn lifetime-unique. Zodra een broche ooit is verkregen,
verdwijnt alleen die broche permanent uit volgende relic-drops. Gewone relieken
en de Spark Astrolabe blijven terugkomen.

Met `b` nog niet verkregen broches geldt:

```text
poolgrootte D = 61 + b
kans per gewone relic na een geslaagde relic-roll = 10 / D
kans op Spark Astrolabe = 1 / D
kans per nog verkrijgbare broche = 1 / D
kans op een al verkregen broche = 0
```

| Nog verkrijgbare broches | Poolgrootte | Elk gewoon reliek | Spark Astrolabe | Iedere resterende broche |
|---:|---:|---:|---:|---:|
| 4 | 65 | 15,384615% | 1,538462% | 1,538462% |
| 3 | 64 | 15,625% | 1,5625% | 1,5625% |
| 2 | 63 | 15,873016% | 1,587302% | 1,587302% |
| 1 | 62 | 16,129032% | 1,612903% | 1,612903% |
| 0 | 61 | 16,393443% | 1,639344% | Niet meer beschikbaar |

Er bestaat geen pity-systeem voor relics. Het openen van meerdere chests voert
voor iedere chest apart de normale roll uit.

## Relics uit chests

Eerst wordt bepaald of de chest überhaupt een relic geeft. Alleen na succes
wordt uit de pool hierboven gekozen.

| Chest | Kans op een relic | Elk gewoon reliek bij de beginpool | Spark of iedere broche bij de beginpool |
|---|---:|---:|---:|
| Wooden | 0% | 0% | 0% |
| Silver | 0% | 0% | 0% |
| Gold | 1% | 0,153846% | 0,0153846% |
| Dragon | 2% | 0,307692% | 0,0307692% |
| Mythical | 4% | 0,615385% | 0,0615385% |
| Sinister | 100% | 15,384615% | 1,538462% |
| Special, Portrait, Title of Music | 0% | 0% | 0% |

De relic-roll staat los van de coin-, gem-, egg- en emote-roll van dezelfde
chest. Egg pity verandert de relic-kans niet.

## Adventures als chest-route

Een Adventure rolt of kent eerst een chest toe. De relic-roll gebeurt pas
wanneer die chest later wordt geopend.

| Adventure | Chestverdeling | Kans dat de toegekende chest later een relic geeft |
|---|---|---:|
| Mini | 100% Wooden | 0% |
| Short | 20% Wooden; 40% Silver; 35% Gold; 4,5% Dragon; 0,5% Mythical | 0,46% |
| Long | 75% Gold; 23% Dragon; 2% Mythical | 1,29% |
| Group | 70% Gold; 25% Dragon; 5% Mythical | 1,40% |

Een specifieke relic gebruikt daarna de actuele `10 / D`- of `1 / D`-poolkans.

Een vrijgelaten draak kan een 48 uur beschikbare Special Adventure achterlaten.
Zo'n huidige, speelbare route toont vooraf één vaste chest. Wooden en Silver
hebben geen relic; Gold, Dragon en Mythical gebruiken hun normale kansen uit de
chesttabel. Een Sinister-returnroute toont een Sinister Chest en die chest geeft
gegarandeerd een relic. De dagelijkse return-roll en het returnresultaat staan
los van de latere chestinhoud. Een vrijgelaten draak kan bij een ander
returnresultaat ook rechtstreeks een chest achterlaten; bij het openen gelden
dezelfde chestkansen.

Kalenderevents starten tegenwoordig geen seizoensgebonden Special Adventure
meer. Adventures en Trials vullen tijdens het event een puntenmeter; de huidige
eventbeloning is uitsluitend de ingestelde event-Special Chest. Deze
event-Special Chests hebben geen Mystic Relic-roll.

Alleen een **historische Golden Wings-run die al gestart en opgeslagen was**
kan bij claim nog de oude directe beloning geven: exact één van Moral Prism,
Order Compass, Soul Mirror en Astral Lens, ieder met 25% kans. Een nieuwe
Golden Wings Special Adventure kan niet meer worden gestart, dus dit is geen
huidige verkrijgingsroute. Een productiepreview geeft die oude
Adventure-beloning evenmin.

## Trials als relic-route

Alleen een **S+** voltooiing doet rechtstreeks een onafhankelijke relic-roll van
**1%**. Bij de beginpool is dat 0,153846% per gewoon reliek en 0,0153846% voor de
Spark Astrolabe of iedere nog verkrijgbare broche.

De chest die een Trial oplevert is een tweede, aparte route:

| Grade | Chestverdeling | Kans op een relic wanneer die chest wordt geopend | Extra directe roll |
|---|---|---:|---:|
| D | Geen chest | 0% | 0% |
| C | 100% Wooden | 0% | 0% |
| B | 85% Wooden; 10% Silver; 5% Gold | 0,05% | 0% |
| A | 30% Wooden; 50% Silver; 20% Gold | 0,20% | 0% |
| S | 30% Silver; 69% Gold; 1% Dragon | 0,71% | 0% |
| S+ | 90% Gold; 9% Dragon; 1% Mythical | 1,12% | 1% |

Bij S+ is de kans op minstens één relic over de directe roll en de later
geopende chest samen **2,1088%**. De kans dat beide routes een relic geven is
**0,0112%**. Als de directe drop een nieuwe broche is, wordt die broche voor de
latere chest uit de pool verwijderd.

## Shop, ruilen en codes

- Moral Prism, Order Compass, Soul Mirror en Astral Lens kosten ieder exact
  **500 gems**. Er is geen aankooplimiet en geen willekeurige selectie.
- Shop-exemplaren zijn niet ruilbaar.
- Gameplay-exemplaren van de zes relieken met gewicht 10 zijn wel ruilbaar.
- Spark Astrolabe en alle vier broches zijn altijd niet ruilbaar.
- Ruilen voegt geen kansberekening toe: beide spelers kiezen hun voorwerp.
- De huidige code-rewardtypes geven geen relic rechtstreeks. Een generieke,
  geldige evenementpreview kan content beschikbaar maken, maar gebruikt voor
  eventuele Trial-rewards dezelfde normale tabellen hierboven. Actieve
  codewaarden horen niet in een spelersgids.

## Egg Altar Relics

Egg Altar Relics worden gegarandeerd gemaakt wanneer de speler voldoende
materialen heeft. Zij hebben een aparte voorraad, komen niet in de Mystic
Relic-drop-pool en zijn niet ruilbaar.

| Engelse naam in de game | Kosten: Fragments | Essence | Weaveheart | Effect |
|---|---:|---:|---:|---|
| Moral Echo | 20 | 1 | 0 | Onthult de morele aard van een ei. |
| Order Sigil | 30 | 2 | 0 | Onthult de orde-aard van een ei. |
| Astral Lens | 50 | 5 | 1 | Onthult de zeldzaamheid van een ei. |
| Weave Oracle | 125 | 12 | 2 | Onthult de drakenfamilie en zeldzaamheid van een ei. |
| Nameweaver's Quill | 10 | 1 | 0 | Hernoemt één al benoemde, uitgekomen draak. |

De Altar Astral Lens en de Mystic Astral Lens zien er hetzelfde uit en hebben
hetzelfde basisdoel, maar zijn technisch en qua voorraad twee aparte
voorwerpen. Weave Oracle en Nameweaver's Quill zijn uitsluitend via het Altar
verkrijgbaar. Een scan op informatie die al bekend is verbruikt geen extra
Altar Relic en rerollt het ei niet.

## Materialen van Return to the Weave

| Teruggegeven ei | Gegarandeerde Fragments | Essence | Losse Weaveheart-roll |
|---|---:|---|---:|
| Geschikt gewoon inventory-ei | 5 | 25% op precies 1; anders 0 | 2% op precies 1 |
| Sinister Egg | 25 | Altijd 3, 4 of 5; ieder exact 1/3 | 10% op precies 1 |

De Essence- en Weaveheart-roll zijn onafhankelijk. Na 39 opeenvolgende returns
zonder Weaveheart geeft de volgende return gegarandeerd precies één
Weaveheart. Iedere succesvolle Weaveheart reset deze teller.

Special-family-eieren, getagde eieren, het ei in het nest en voor ruil
gereserveerde eieren kunnen niet worden teruggegeven. Getagde eieren mogen wel
met een al gemaakt informatie-reliek worden gescand.

## Bronnen

De regels in deze gids volgen rechtstreeks uit:

- `lib/models/mystic_relic.dart`
- `lib/providers/household_provider.dart`
- `lib/providers/dragonhaven_systems.dart`
- `lib/models/trial.dart`
- `lib/models/adventure.dart`
- `lib/models/egg_altar.dart`
- `lib/providers/egg_altar_systems.dart`
- `RANDOM_REWARDS_AND_ODDS.md`
