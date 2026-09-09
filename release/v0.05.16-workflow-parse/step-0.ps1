if ($env:CONFIRMATION -cne 'MIGRATE_PRODUCTION_42_TO_44') {
  throw 'The required production confirmation is missing.'
}
