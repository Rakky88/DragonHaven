$ErrorActionPreference = 'Stop'
$env:JAVA_HOME='C:/Program Files/Android/Android Studio/jbr'
$apk='release/DragonHaven-v0.05.18.apk'
$badging = & 'C:/Users/groot/AppData/Local/Android/Sdk/build-tools/36.0.0/aapt.exe' dump badging $apk
if ($LASTEXITCODE -ne 0 -or ($badging -join "`n") -notmatch "package: name='nl.dragonhaven.app' versionCode='10068' versionName='0.05.18'") { throw 'APK package/version mismatch' }
$badging | Set-Content release/v0.05.18-apk-badging.txt
$signature = & 'C:/Users/groot/AppData/Local/Android/Sdk/build-tools/36.0.0/apksigner.bat' verify --verbose --print-certs $apk
if ($LASTEXITCODE -ne 0 -or ($signature -join "`n") -notmatch '477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942') { throw 'APK stable signing mismatch' }
$signature | Set-Content release/v0.05.18-signature.txt
[ordered]@{Version='0.05.18';VersionCode=10068;Commit=(git rev-parse HEAD);SizeBytes=(Get-Item $apk).Length;Sha256=(Get-FileHash $apk -Algorithm SHA256).Hash.ToLowerInvariant();Certificate='477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942'} | ConvertTo-Json | Set-Content release/v0.05.18-artifact.json
Get-Content release/v0.05.18-artifact.json
