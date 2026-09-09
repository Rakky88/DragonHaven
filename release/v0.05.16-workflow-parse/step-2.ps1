foreach ($name in @('SUPABASE_ACCESS_TOKEN', 'SUPABASE_DB_PASSWORD')) {
  if ([string]::IsNullOrWhiteSpace(
      [Environment]::GetEnvironmentVariable($name))) {
    throw "Missing production secret: $name."
  }
}
