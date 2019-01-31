#!/bin/bash

set -ex

die() {
  echo "$1" >&2
  exit 1
}

sudo su gpadmin -l -c "createdb gpadmin" || die "Failed to create gpadmin user database"

sudo su gpadmin -l -c "psql -d gpadmin -c 'SELECT version();'" || die "Failed to install Greenplum"

echo "Installed languages:"
sudo su gpadmin -l -c "psql -d gpadmin -c 'SELECT * from pg_language;'"

if [[ "$INSTALLED_POSTGIS" == "true" ]]; then
  sudo su gpadmin -l -c "psql -d gpadmin -c 'SELECT PostGIS_full_version();'" || die "Failed to install PostGIS"
fi

if [[ "$INSTALLED_PLR" == "true" ]]; then
  sudo su gpadmin -l -c "psql -d gpadmin -c \"
    CREATE OR REPLACE FUNCTION r_version() RETURNS text AS 'R.Version()' LANGUAGE 'plr';
    SELECT r_version();
  \"" || die "Failed to execute R function"
fi

echo "Assigning sudo rights to gpadmin"
sudo /bin/bash -c 'echo "gpadmin ALL=(ALL) ALL" >> /etc/sudoers.d/gpadmin; chmod 0440 /etc/sudoers.d/gpadmin'

echo "Done."

sudo rm -rf /home/configuser/*
