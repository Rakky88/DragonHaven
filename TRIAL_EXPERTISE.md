# Hoe expertise helpt bij elke trial

Alle getrainde punten tellen mee; de oude hulpgrenzen van 300/400 punten zijn weg.
Expertise vermenigvuldigt de score niet. Hieronder zijn M, A en S de Might-,
Arcana- en Spiritpunten van je draak. Percentageverbeteringen zijn relatief
tegenover de gewone zone, breedte, snelheid of marge.

| Trial | Hulp door expertise |
|---|---|
| Cavern Flight | Botsingszone `S / 100 %` kleiner: 950 geeft 9,5%, 1100 geeft 11%. |
| Ruin Breaker | Gewone raakzone `(M / 100) * 1,5 %` breder; perfecte zone `(M / 100) * 0,5 %` breder. |
| Runeweaver | Elke rune blijft `500 + A / 10` ms zichtbaar, afgerond op hele ms. De bestaande extra herinnering vanaf 240 Arcana blijft. |
| Halloween | Volgende pompoenpreview `max(100, A)` ms, na de vorige feedback; eerste preview 2.900 ms. Toegestane afstand tot het padmidden `12 + S / 200` schermpunten. |
| Christmas | Cadeaus krijgen `M / 1000 * 3` seconden extra. De versnelling is `S / 100 %` trager. De bestaande ruimere aflevermarge blijft. |
| New Year | Tikvenster aan beide kanten van de lijn `0,18 + M / 10000` seconde. Noten verschijnen `S / 10000 * 4` seconden eerder. |
| Valentine | 1 hint, 2 vanaf 400 Arcana, 3 vanaf 800, 4 vanaf 1200. Spirit geeft `S / 100` seconden extra. |
| Pride | Dezelfde hint- en tijdsverdeling als Valentine. |
| Birthday | Beginlaag `M / 100 %` breder; perfecte stapelmarge `A / 100 %` groter; bewegende lagen `S / 100 %` trager. |
| Sunwake | Koraal `M / 100 %` smaller; oppakbereik `A / 100 %` groter; zijwaartse stroming `S / 100 %` zwakker. |
| Harvestmoon | Kans op een eenvakstuk: de basiskans van 10% plus `(M + A + S) / 50` procentpunt. Bij totaal 1200 is dat 34%. |

Halloween, Christmas, Valentine, Pride en Harvestmoon starten met 75 seconden,
plus `(M + A + S) / 1000 * 3` seconden. De extra Spirittijd bij Valentine en
Pride komt daar bovenop. Cavern Flight, Runeweaver, Sunwake, New Year en Birthday
hebben geen tijdslimiet. Ruin Breaker behoudt zijn 30 slagen of drie missers.
Birthday eindigt bij één misser; Sunwake en New Year bij drie.

Geen van de eventtrials heeft een scoreplafond of een maximumaantal scoreacties.
De tijdslimieten van de vijf genoemde spellen blijven gelden. De S+-grenzen
blijven Halloween 2000, Christmas 7500, New Year 20000, Valentine 10000,
Pride 12000 en Birthday 10000; ook de andere rankgrenzen blijven gelijk.

Bronnen: `trial_expertise.dart`, `trial.dart`, `trial_run_model.dart` en de
bijbehorende spelmodellen. Dezelfde regels worden gebruikt door de app en
het deterministische servermodel.
