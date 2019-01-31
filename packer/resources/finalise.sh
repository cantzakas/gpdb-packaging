#!/bin/bash

set -ex

die() {
  echo "$1" >&2
  exit 1
}

sudo su gpadmin -l -c "createdb gpadmin" || die "Failed to create gpadmin user database"

sudo su gpadmin -l -c "psql -d gpadmin -c 'SELECT version();'" || die "Failed to install Greenplum"

if [[ "$INSTALLED_POSTGIS" == "true" ]]; then
  sudo su gpadmin -l -c "psql -d gpadmin -c 'select PostGIS_full_version();'" || die "Failed to install PostGIS"
fi

echo "Assigning sudo rights to gpadmin"
sudo /bin/bash -c 'echo "gpadmin ALL=(ALL) ALL" >> /etc/sudoers.d/gpadmin; chmod 0440 /etc/sudoers.d/gpadmin'

echo "Done."

sudo rm -rf /home/configuser/*
