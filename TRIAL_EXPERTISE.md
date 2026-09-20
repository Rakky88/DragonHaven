# Hoe expertise helpt bij elke trial

Expertise maakt de bediening iets vergevingsgezinder. Ze vermenigvuldigt je
score niet. De nieuwe gezamenlijke trainingslimiet verandert deze bestaande
spelvoordelen niet: gewone trials gebruiken maximaal 300 punten voor hun hulp,
eventtrials maximaal 400 per expertise. Meer punten blijven nuttig voor
avonturen, maar versterken deze trialhulp niet verder.

Bij alle eventtrials met een tijdslimiet geven **Might + Arcana + Spirit samen**
ook maximaal 3 extra seconden: `round(totaal / 300)`, begrensd op 0–3.
Dat is +1 seconde vanaf 150, +2 vanaf 450 en +3 vanaf 750 punten.
Sunwake en New Year hebben geen tijdslimiet en gebruiken deze tijdsbonus dus niet.

| Trial | Might | Arcana | Spirit |
|---|---|---|---|
| **Cavern Flight** | Geen effect | Geen effect | Verkleint de afmetingen van de botsingszone met maximaal 10% bij 300 punten. |
| **Ruin Breaker** | Maakt de gewone raakzone tot 15% en de perfecte raakzone tot 5% breder bij 300 punten. | Geen effect | Geen effect |
| **Runeweaver** | Geen effect | Runen blijven 500–600 ms zichtbaar. Vanaf 240 punten krijg je één extra herinnering aan de laatste rune, vanaf de vierde ronde. | Geen effect |
| **Witchlight Ward — Halloween** | Draagt bij aan de gezamenlijke tijdsbonus. | Laat de pompoen bij volgende rondes maximaal 800 ms langer zien. De eerste preview blijft 2,9 seconden. Ook de tijdsbonus. | Vergroot de toegestane afstand tot het midden van het pad van 12 tot 16 schermpunten. Ook de tijdsbonus. |
| **Hollyfrost Giftforge — kerst** | Geeft elk cadeau maximaal 0,35 seconde extra voordat het van de band valt. Ook de tijdsbonus. | Alleen de tijdsbonus. | Alleen de tijdsbonus. |
| **Midnight Chime — oud en nieuw** | Vergroot het toegestane tikvenster van ±0,18 tot ±0,25 seconde. | Geen effect. | Geeft vallende noten tot 0,4 seconde extra reistijd, zodat je ze eerder ziet. |
| **Rosevow Relay — Valentijn** | Alleen de tijdsbonus. | 1 hint bij minder dan 200 punten, 2 vanaf 200 en 3 vanaf 400. Ook de tijdsbonus. | Alleen de tijdsbonus. |
| **Prismatic Parade — Pride** | Alleen de tijdsbonus. | 1 hint bij minder dan 200 punten, 2 vanaf 200 en 3 vanaf 400. Ook de tijdsbonus. | Alleen de tijdsbonus. |
| **Wishcake Tower — verjaardag** | Vergroot de beginbreedte van de taart van 44% tot 48% van het speelveld. | Vergroot de marge voor perfect stapelen van 1,8% tot 2,5% van de speelveldbreedte. | Geeft bewegende lagen tot 8% meer tijd om over te steken. Alle drie tellen ook mee voor de tijdsbonus. |
| **Sunwake Surf** | Verkleint de koraalbreedte van 25% tot 22,5% van het speelveld. | Vergroot het bereik om zonneparels op te pakken van 10% tot 12,5% van de speelveldbreedte. | Verzwakt de zijwaartse stroming met maximaal 25%. |
| **Moonlit Orchard — Harvestmoon** | Verhoogt de kans op een klein éénvakstuk. | Verhoogt dezelfde kans. | Verhoogt dezelfde kans. Per expertise maximaal +3,5 procentpunt: gezamenlijk van 10% tot 20,5%. Alle drie tellen ook mee voor de tijdsbonus. |

Deze grenzen zijn hulpgrenzen van de spellen, geen trainingslimieten voor je
draak. Bronnen: `trial.dart`, `classic_trial_game.dart`, `trial_run_model.dart`,
`seasonal_arcade_game.dart`, `seasonal_minigame.dart`, `witchlight_trace.dart`,
`wishcake_tower.dart`, `sunwake_surf.dart` en `moonlit_orchard.dart`.
