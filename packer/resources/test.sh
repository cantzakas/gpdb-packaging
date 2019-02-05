#!/bin/bash
set -e

# This script runs as gpadmin

die() {
  echo "$1" >&2
  exit 1
}

createdb gpadmin || die "Failed to create gpadmin user database"
psql -d gpadmin -c 'SELECT version();' || die "Failed to install Greenplum"

echo "Installed languages:"
psql -d gpadmin -c "
  SELECT lanname AS Language, lanpltrusted::text AS Is_Trusted
  FROM pg_language
  WHERE lanname NOT IN ('internal', 'c', 'sql', 'plpgsql');
"

if [[ "$INSTALLED_POSTGIS" == "true" ]]; then
  psql -d gpadmin -c "SELECT PostGIS_full_version();" || die "Failed to install PostGIS"
fi

if [[ "$INSTALLED_PLR" == "true" ]]; then
  psql -d gpadmin -c "CREATE FUNCTION test_r_version() RETURNS text AS 'R.Version()\$version.string' LANGUAGE 'plr';" \
    || die "Failed to create PL/R function"

  psql -d gpadmin -c "SELECT test_r_version();" || die "Failed to execute PL/R function"
fi
