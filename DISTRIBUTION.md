# DragonHaven publiceren en updaten

De update- en kopieerknoppen in **About DragonHaven** gebruiken de nieuwste openbare GitHub Release. Android vraagt altijd zelf om bevestiging voordat een APK wordt geïnstalleerd.

## Updatecompatibiliteit

De zichtbare app en het releasebestand heten **DragonHaven**. Het vaste Android application ID is `nl.dragonhaven.app`. Dit is bewust een nieuwe app; oudere installaties met het voormalige ID mogen worden verwijderd. Alle toekomstige DragonHaven-versies moeten dit nieuwe ID behouden.

Android accepteert een update alleen wanneer iedere release met dezelfde privésleutel is ondertekend. Bewaar de bestaande keystore veilig en commit nooit de keystore of `android/key.properties`.

De releaseworkflow verwacht deze GitHub-secrets:

- `DRAGONHAVEN_KEYSTORE_BASE64`
- `DRAGONHAVEN_KEYSTORE_PASSWORD`
- `DRAGONHAVEN_KEY_ALIAS`
- `DRAGONHAVEN_KEY_PASSWORD`

De secret-namen blijven om compatibiliteitsredenen gelijk; ze zijn niet zichtbaar in de app.

## Release

Repository: `Rakky88/DragonHaven`

Releasepagina:

```text
https://github.com/Rakky88/DragonHaven/releases/latest
```

Permanente directe Android-download:

```text
https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk
```

Een release-tag gebruikt dezelfde weergaveversie als About, bijvoorbeeld `v0.00.09`, en bevat een asset met exact de naam `DragonHaven.apk`.

Lokale forks kunnen `DRAGONHAVEN_GITHUB_OWNER`, `DRAGONHAVEN_GITHUB_REPO` en `DRAGONHAVEN_APP_VERSION` via `--dart-define` overschrijven.
