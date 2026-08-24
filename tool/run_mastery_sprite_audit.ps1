param(
  [string]$DeviceId = ''
)

$flutter = Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat'
$arguments = @(
  'run',
  '--dart-define=DRAGONHAVEN_SPRITE_AUDIT=true',
  '--dart-define=DRAGONHAVEN_MASTERY_AUDIT_ONLY=true'
)
if ($DeviceId) {
  $arguments += @('-d', $DeviceId)
}

& $flutter @arguments
