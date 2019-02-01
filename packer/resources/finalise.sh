#!/bin/bash

set -ex

die() {
  echo "$1" >&2
  exit 1
}

sudo su gpadmin -l -c "createdb gpadmin" || die "Failed to create gpadmin user database"

sudo su gpadmin -l -c "psql -d gpadmin -c 'SELECT version();'" || die "Failed to install Greenplum"

echo "Installed languages:"
sudo su gpadmin -l -c "psql -d gpadmin -c 'SELECT lanname AS Language, CASE WHEN lanpltrusted THEN '\''true'\'' ELSE '\''false'\'' END AS Is_Trusted FROM pg_language WHERE lanname NOT IN ('\''internal'\'', '\''c'\'', '\''sql'\'', '\''plpgsql'\'');'"

if [[ "$INSTALLED_POSTGIS" == "true" ]]; then
  sudo su gpadmin -l -c "psql -d gpadmin -c 'SELECT PostGIS_full_version();'" || die "Failed to install PostGIS"
fi

if [[ "$INSTALLED_PLR" == "true" ]]; then
  sudo su gpadmin -l -c "psql -d gpadmin -c 'CREATE OR REPLACE FUNCTION test_r_version() RETURNS text AS \$\$ R.Version()\$version.string \$\$ LANGUAGE '\''plr'\'';'" \
    || die "Failed to create test_r_version() function"
  sudo su gpadmin -l -c "psql -d gpadmin -c 'SELECT test_r_version();'" \
    || die "Failed to execute test_r_version() function"
fi

echo "Assigning sudo rights to gpadmin"
sudo /bin/bash -c 'echo "gpadmin ALL=(ALL) ALL" >> /etc/sudoers.d/gpadmin; chmod 0440 /etc/sudoers.d/gpadmin'

echo "Done."

sudo rm -rf /home/configuser/*
