# Egg Altar - ontwerpvoorstel

Status: uitgebracht op 7 september 2026 in **v0.05.16 / versionCode 10066**.
Analyzer schoon en 486 tests groen; staging en productie staan op 44/44 migraties.
Stagingrun 34106264418 en productierun 34107061124 bevestigen de teruggerolde
contractrepetitie, migratiepariteit, nul database-lintfouten en groene healthchecks.
De ondertekende APK en vaste downloadlink zijn gecontroleerd; ook de servercheck
na publicatie is groen. De startbalans hieronder is ingebouwd.
Dit document behoudt zijn oorspronkelijke
bestandsnaam zodat verwijzingen naar het plan blijven werken.

Vastgelegde keuzes van de speler:
- Astral Lens blijft ook uit de bestaande drops komen; die relic wordt niet exclusief.
- Weave Oracle en de nieuwe consumable voor drakennaamswijzigingen zijn exclusief
  via crafting bij het Egg Altar verkrijgbaar.
- Eieren kunnen worden getagd en ontagd; getagde eieren mogen nooit naar de Weave.
- De terugkeeranimatie krijgt zes fasen, met zes eigen sprites en vloeiende crossfades.
- Sinister-eieren mogen naar de Weave: altijd 25 Fragments en 3–5 Essence,
  met 10% kans op één Weaveheart. Het extra bevestigingsscherm noemt geen opbrengst.
- De gezamenlijke cosmetische Conclave Weave Beacon wordt direct meegenomen.

## Doel

Overtollige eieren een betekenisvolle bestemming geven: ruimte maken, materialen
verzamelen en gerichte informatie over andere eieren verdienen. Uitbroeden moet
waardevol blijven. Het altaar is permanent en staat bij Inventory > Eggs, met een
eigen scherm en een lokale doorgang vanaf het nest/een passende torenruimte.

De bestaande Dragon-, Mythical- en Sinister-chests geven gegarandeerd een ei.
Het altaar vangt overschotten op, maar vervangt geen latere meting van de verhouding
tussen ei-aanvoer en uitbroedsnelheid. Niet tegelijk de drops verlagen: eerst meten.

## Return to the Weave

1. Kies een ei uit de voorraad; getagde en gereserveerde eieren zijn beschermd.
2. Toon uitsluitend reeds bekende kenmerken en vermeld dat dit ei verdwijnt.
3. Houd Return to the Weave kort ingedrukt om de definitieve keuze te bevestigen.
4. Het ei zweeft boven het altaar en lost op in zachte lichtdraden naar de Weave.
5. Materialen verschijnen en worden opgeteld in een aparte, stapelbare wallet.

Eieren met een draak van rarity specialEvent zijn altijd uitgesloten, ook bij
legacy/importdata. Controleer de echte familie, niet alleen het plaatje of de naam.
Het actieve nestei, trade-reserveringen en getagde eieren zijn niet selecteerbaar.
Sinisterra is Mythical en mag naar de Weave. Na de vasthoudknop verschijnt nog
een extra bevestigingsscherm dat alleen de definitieve teruggave vermeldt.
Een Sinister-ei geeft altijd 25 Fragments en 3–5 Essence, met 10% kans op één
Weaveheart; de pityteller telt eenmaal.
Geen automatische selectie op verborgen rarity of Spectral-status.
Na de eerste volledige animatie mag de speler volgende animaties versnellen.
Een gerichte multiselect kan later, met bescherming per ei; geen select-all als default.

## Eieren taggen en ontaggen

- Elk ei heeft een door de eigenaar aan- en uit te zetten beschermtag. Hiervoor
  worden geen materialen of relics verbruikt.
- Een tagknop staat op de eikaart en in het eidetailvenster, met een zichtbaar
  tagsymbool en de tekst Getagd / Tagged. Dezelfde bediening kan de tag verwijderen.
- Het Egg Altar toont getagde eieren als beschermd, met uitleg dat eerst expliciet
  ontaggen nodig is. De terugkeeractie verwijdert een tag nooit automatisch.
- De tag wordt aan de unieke ei-ID opgeslagen en blijft behouden bij herstart,
  nestwissel en backup/herstel. Bij toegestane overdracht blijft de bescherming
  aan het ei hangen; de nieuwe eigenaar kan zelf ontaggen.
- Taggen verandert geen verborgen ei-eigenschappen. Ook onthullingsrelics mogen
  op getagde eieren worden gebruikt; de bescherming geldt voor Return to the Weave.
- Zowel de selectie als de definitieve verwerking controleert de actuele tag.
  Een inmiddels getagd ei mag ook via een oude selectie, batch of retry niet worden
  teruggegeven. Een oude backup mag een nieuwere bescherming niet stil verwijderen.
- Special-eieren blijven uitgesloten, ook nadat de speler een eigen tag verwijdert.
- Een filter voor Getagd / Niet getagd maakt een grote voorraad overzichtelijk.

De beschermtag vervangt het eerdere losse idee van favorieten in dit plan; hiervoor
worden geen twee overlappende beschermingssystemen gebouwd.

## Materialen - ingebouwde startbalans

| Materiaal | Eigen rarity | Functie | Per gewoon ei |
|---|---|---|---|
| Shell Fragments | Common | Basis voor alle recepten | Altijd 5 |
| Draconic Essence | Rare | Magische informatie-relics | 25% kans op 1 extra |
| Weaveheart | Legendary | Hoogste onthullingsrelics | 2% kans op 1 extra |

De twee rollen zijn onafhankelijk: Essence en Weaveheart kunnen tegelijk
vallen. Sinister geeft altijd 25 Fragments en 3, 4 of 5 Essence met elk een kans
van 1/3. De Weaveheart-kans is vijfmaal zo groot (10%), de opbrengst is één
Weaveheart, ook bij de garantie na 39 gemiste teruggaven. Elk ander
geschikt ei gebruikt dezelfde tabel, ongeacht verborgen drakenrarity,
Spectral-status, hatchseed of herkomst. Geen vergoeding voor een zogenaamd duplicate
ei die stiekem de onbekende inhoud verraadt.

Na 39 teruggaven zonder Weaveheart geeft de 40e er gegarandeerd een. Elke verkregen
Weaveheart reset die teller. Teller per account, geen reset door herstart of Conclave-
wissel; zichtbaar als rustige voortgang. Geen dagelijkse limiet op inventarisopruiming.
Exacte kansen en pity zichtbaar via een informatieknop en in RANDOM_REWARDS_AND_ODDS.md.

## Crafting - ingebouwde recepten

De vier onthullingsrelics zijn consumables voor een specifiek ei. Zij onthullen
vaste informatie, veranderen of rerollen niets. Een relic wordt niet verbruikt als
de informatie al bekend is. Informatie blijft aan de unieke ei-ID gekoppeld, ook bij
nestwissel, backup/herstel en toegestane overdracht. De vijfde relic wijzigt de
gekozen naam van een uitgekomen draak en wordt hieronder afzonderlijk beschreven.

| Relic | Effect | Fragments | Essence | Weaveheart |
|---|---|---:|---:|---:|
| Moral Echo | Good / Neutral / Evil van het ei | 20 | 1 | 0 |
| Order Sigil | Lawful / Neutral / Chaotic van het ei | 30 | 2 | 0 |
| Astral Lens | Exacte rarity van de draak in het ei | 50 | 5 | 1 |
| Weave Oracle | Drakenfamilie en rarity van dit ene ei | 125 | 12 | 2 |
| Nameweaver's Quill | Eenmalig de naam van een eigen draak wijzigen | 10 | 1 | 0 |

De Quill-kosten zijn vastgelegd door de speler; de overige receptkosten zijn
de gekozen startbalans voor de eerste implementatie. Oracle en Quill zijn uitsluitend via het Egg Altar te craften: geen
shopaanbod, chest-drops of rechtstreekse Conclave-beloning.

Weave Oracle onthult de familie, niet een toekomstige ascended vorm, alle traits of
alle toekomstige stats. Familie-onthulling telt niet als hatch/discovery/achievement.
De rarity wordt ook zichtbaar, omdat de familienaam die informatie al impliceert.

Astral Lens blijft beschikbaar via de bestaande drop-pools. Crafting voegt een
extra verkrijgingsroute toe; bestaande exemplaren, dropkansen en het huidige
shopaanbod blijven behouden. Geen herverdeling van de bestaande relic-drop-pools
en geen tweede relic met identieke rarity-functie toevoegen.

### Nameweaver's Quill - exclusieve naamswijzigingsrelic

- Consumable met een eigen sprite: een lichtgevende veer met een draad van de Weave.
- Crafting kost exact 10 Shell Fragments en 1 Draconic Essence, geen Weaveheart.
- Kies een eigen uitgekomen draak, vul de nieuwe naam in en bevestig de wijziging.
  Een geslaagde wijziging verbruikt precies een Quill.
- Eerste naamgeving na het uitkomen blijft gratis. Het plan reserveert de Quill
  voor het later wijzigen van een al gekozen naam. De bestaande nameDragon-route
  moet daarbij worden gecontroleerd, zodat deze geen gratis omweg blijft bieden.
- Houd de huidige naamregels aan: trim spaties, geen lege naam, maximaal 24 tekens.
  Annuleren, een ongeldige naam, dezelfde naam of een mislukte opslag verbruikt niets.
- Alleen de persoonlijke naam verandert: familie, rarity, stats, traits, unieke
  draak-ID, uitrusting en voortgang blijven behouden. Opnieuw benoemen telt niet
  opnieuw voor een achievement voor de eerste naamgeving.
- De naamswijziging en het verbruiken van de Quill vormen een handeling die bij
  retry niet nogmaals wordt afgeschreven. Toon de gewijzigde naam in de collectie
  en in actuele profiel-/sociale samenvattingen waar die draak wordt getoond.

Start met niet-verhandelbare materialen en crafted relics. Zo kan de nieuwe economie
worden gemeten zonder dat materialen direct via secundaire accounts rondgaan.
Geen gouden/gem-vergoeding en geen recept dat nieuwe eieren maakt: de lus moet het
overschot verkleinen. Een later optioneel recept kan een decoratie uit veel Fragments
maken, voor spelers die geen informatie-relics meer nodig hebben.

## Conclave - gezamenlijke Weave Beacon

De gedeelde Weave Beacon staat direct in de Aerie. De drie cosmetische mijlpalen
liggen op 500, 2000 en 5000 Shell Fragments; daarna stopt de inzameling.
Spelers schenken vrijwillig een deel van hun eigen Shell Fragments. Een project kan
eindigen in een Conclave-banner, altaargloed, emote of cosmetische Aerie-versiering.
Geen persoonlijke teruggave automatisch afromen. Geen eis om Weavehearts of eieren
in te leveren. Geen individuele minimumquota of lijst van achterblijvers. Een
Conclave biedt in de eerste versie geen betere droprates of exclusieve scanfunctie.
Solo-spelers moeten dezelfde informatie over hun eieren kunnen verkrijgen.
Publiceer hoogstens een samengevoegde projectmelding in de chat; geen melding per ei.

Mogelijke latere aanvulling: Conclave-versies van de altaarvormgeving en recepten
voor gedeelde decoratie met Fragments. Geen gedeelde toegang tot persoonlijke eieren.

## Art en audio

- Leeg Egg Altar: eigen transparante sprite, stenen kom met zachte runen.
- Actief altaar: basislaag en losse eilayer, zodat ei-typen correct blijven.
- Zes animatiefasen met een eigen sprite per fase:
  1. De altaarrunen ontwaken en beginnen te gloeien.
  2. Het ei stijgt op boven de kom.
  3. De Weave opent en lichtdraden omringen het ei.
  4. Het ei gaat geleidelijk over in lichtdraden.
  5. De lichtdraden keren terug naar de Weave.
  6. Het altaar dooft rustig uit en de ontvangen materialen verschijnen.
  De zes sprites gaan in 220 ms vloeiend in elkaar over binnen een animatie van
  4,2 seconden; de eilayer stijgt en verdwijnt geleidelijk. Het lege altaar en de
  bezette toestand blijven ook als
  afzonderlijke, herbruikbare weergaven beschikbaar.
- Drie afzonderlijke resourcesprites, ook herkenbaar zonder raritykleur:
  Shell Fragments als gladde parelmoerscherven; Essence als opkrullende drakenvlam;
  Weaveheart als gevlochten kristalkern met een zachte lichtpuls.
- Vier nieuwe relicsprites: Moral Echo, Order Sigil, Weave Oracle en Nameweaver's
  Quill. De bestaande Astral Lens behoudt zijn sprite.
- Een herkenbaar tagsymbool en duidelijke getagde/ontagde toestand op eikaarten.
- Rustig terugkeergeluid; geen breek-/vernietigingsanimatie. Reduced motion gebruikt
  een korte fade. Vanaf de tweede keer versnelbare animatie.

## Implementatie en controle

De app gebruikt save-schema 54 en een aparte Altar-wallet. Servermigratie 42 voegt
uitsluitend het Altar-register en zijn transacties toe; de brede economycutover
blijft uit. Bestaande inventarisregistratie blijft een legacy vertrouwensgrens.
Eenmaal geregistreerde ei-ID's hebben vaste familie/eigenaar, tags, kennis en een
blijvende markering na teruggave. Oude inventarissynchronisatie kan die markering
niet verwijderen. Bestaande toegestane trades nemen beschermtags en kennis mee.

Elke online actie bewaart eerst een request-ID. Servercontrole, materiaalmutatie,
consumable en ontvangstbewijs worden atomair verwerkt. Na een verloren antwoord
kan dezelfde actie veilig worden hervat. Een andere actie wacht op die afronding.
In de productieconfiguratie is een online account nodig voor Altar-acties.

De aanvullende migratie 44 wijzigt uitsluitend de beloning van nieuwe Sinister-
teruggaven. Bestaande ontvangstbewijzen, wallets en de pityteller blijven behouden.

Tests omvatten beschermde/legacy Special-eieren, Sinister-bevestiging zonder
opbrengsttekst, de exacte 10%-grens, de drie Essence-uitkomsten en één-heart-pity,
herhaald teruggeven, oude backups, taggen/ontaggen, vaste onthullingen, Quill-kosten,
neutrale bestaande drop-pools en herstel na een verloren serverantwoord. Compacte
widgettests behandelen de selectie, hold/annulering, tags en Beacon-giften.
De SQL-contracttest draait met tijdelijke accounts in een teruggerolde transactie.
Staging voert eerst migraties plus contract als teruggedraaide repetitie uit,
daarna pas de echte migratie, opnieuw het contract, database-lint en healthchecks.

## Latere uitbreidingen

Gerichte multiselect, meer cosmetische fragmentrecepten en optionele Conclave-
varianten blijven vervolgwerk. Meet eerst ei-aanvoer, teruggaven en materiaalgebruik
voordat dropkansen of recepten worden aangepast. Geen verborgen-rarityselectie,
geen beloningen voor bekendgemaakte informatie en geen extra hatch-claims.
