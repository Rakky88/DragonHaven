# DragonHaven v0.04.13

- Android vraagt notificatierechten niet langer opnieuw aan bij iedere koude
  start nadat de speler de toestemming al heeft geweigerd. Hierdoor kan
  Androids Permission Controller de app niet meer onverwacht naar de
  achtergrond of het startscherm drukken.
- De automatische rechtenvraag gebeurt alleen nog één keer bij een werkelijk
  nieuwe installatie en pas nadat DragonHaven volledig op de voorgrond staat.
  Bestaande en bijgewerkte installaties respecteren de eerder gemaakte keuze.
- Het scherm Notificaties toont voortaan duidelijk wanneer Android-meldingen
  voor DragonHaven uitstaan en biedt een bewuste knop naar de juiste
  systeeminstellingen.
- De fix is op het betrokken fysieke Android 15-toestel gecontroleerd met drie
  koude starts: geen nieuwe rechtenaanvraag, geen geblokkeerde achtergrondstart
  en geen crash. De speldata en serverconfiguratie blijven ongewijzigd.
- De nieuwe interface-teksten zijn beschikbaar in alle acht ondersteunde
  talen.
