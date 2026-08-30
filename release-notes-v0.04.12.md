# DragonHaven v0.04.12

- Een online refresh-storm is opgelost. Gelijktijdige verversingen delen nu
  één serveraanvraag en automatische refreshes vanuit initialisatie,
  schermnavigatie en app-resume worden veilig begrensd. Handmatig verversen
  blijft direct beschikbaar.
- De overbodige online refresh bij het openen van Adventure is verwijderd. Dit
  voorkomt het snelle flikkeren en vastlopen dat in de meegestuurde diagnose
  zichtbaar was, ook direct na een appherstart.
- De chest-reveal heeft een compacter kaartontwerp, een duidelijk
  beloningenpaneel en een vaste Verder-knop. Grote batchbeloningen blijven in
  een begrensd, scrollbaar overzicht passen.
- Chest- en effectafbeeldingen worden tijdens de reveal op een passend formaat
  gedecodeerd en de zweefanimatie stopt zodra het openen begint. Daardoor zijn
  geheugen- en GPU-pieken op telefoons aanzienlijk kleiner.
- Afgeronde solo Adventures tonen voortaan direct hun XP, expertise en het
  exacte gewonnen kisttype. De verborgen kist-roll wordt bij de start veilig
  opgeslagen en kan na een appherstart niet veranderen.
- Afgeronde Group Adventures tonen duidelijk de vaste XP, expertise en de
  mogelijke Gold-, Dragon- of Mythical Chest-beloning.
- De nieuwe interface-teksten zijn beschikbaar in alle acht ondersteunde
  talen.
