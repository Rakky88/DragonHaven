# DragonHaven release requirement

Before publishing any DragonHaven release, run
`tool/release_server_preflight.ps1` against the linked Supabase project. Do not
publish when migrations differ, database lint reports an error, or either
public Auth endpoint is unhealthy. This preflight is mandatory in addition to
Flutter analysis, tests, APK signature/version checks and the GitHub publisher
dry run.
