$ErrorActionPreference = 'Stop'
$localArtifact = Get-Content release/v0.05.17-artifact.json -Raw | ConvertFrom-Json
$release = (& 'C:/Program Files/GitHub CLI/gh.exe' api repos/Rakky88/DragonHaven/releases/tags/v0.05.17 | Out-String) | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $release.tag_name -ne 'v0.05.17' -or $release.draft) { throw 'Expected public release not found.' }
$asset = @($release.assets | Where-Object name -eq 'DragonHaven.apk')
if ($asset.Count -ne 1 -or $asset[0].state -ne 'uploaded' -or $asset[0].size -ne $localArtifact.SizeBytes -or $asset[0].digest -ne ('sha256:' + $localArtifact.Sha256)) { throw 'Remote artifact does not match local SHA-256 and byte size.' }
$latest = (& 'C:/Program Files/GitHub CLI/gh.exe' api repos/Rakky88/DragonHaven/releases/latest | Out-String) | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $latest.tag_name -ne 'v0.05.17') { throw 'Latest points at the wrong release.' }
$permanent = 'https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk'
$download = Invoke-WebRequest -UseBasicParsing -Method Head -Uri $permanent -MaximumRedirection 10
if ($download.StatusCode -ne 200 -or [long]$download.Headers['Content-Length'] -ne $localArtifact.SizeBytes) { throw 'Permanent download verification failed.' }
[ordered]@{CheckedAtUtc=[DateTime]::UtcNow.ToString('o');Version=$release.tag_name;ReleaseUrl=$release.html_url;AssetUrl=$asset[0].browser_download_url;LatestDownloadUrl=$permanent;SizeBytes=$asset[0].size;Sha256=$localArtifact.Sha256;RemoteDigestMatches=$true;LatestMatches=$true;DownloadStatus=$download.StatusCode} | ConvertTo-Json | Set-Content release/v0.05.17-remote-verification.json
Get-Content release/v0.05.17-remote-verification.json
./tool/public_server_health_check.ps1 -Environment production -OutputPath release/v0.05.17-health-after-publication.json
