when defined(postgres):
  import repository/postgresRepository
  export postgresRepository
elif defined(sqlite):
  import repository/sqliteRepository
  export sqliteRepository
else:
  {.error: "Snorlogue requires you to specify which database type you use via a defined flag. Please specify either '-d:sqlite' or '-d:postgres'".}
