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

if [[ "$INSTALLED_PLPY" == "true" ]]; then
  psql -d gpadmin -c "CREATE FUNCTION test_py_version() RETURNS text AS 'import sys; return sys.version' LANGUAGE 'plpythonu';" \
    || die "Failed to create PL/Python function"

  psql -d gpadmin -c "SELECT test_py_version();" || die "Failed to execute PL/Python function"
fi

if [[ "$INSTALLED_PLCONTAINER" == "true" ]]; then
  echo "Installed container images:"
  plcontainer image-list

  psql -d gpadmin -c "SELECT * FROM plcontainer_show_config;"
fi

if [[ "$INSTALLED_PLCONTAINER_R" == "true" ]]; then
  psql -d gpadmin -c "CREATE FUNCTION test_container_r_version() RETURNS text AS \$\$
      # container: plc_r
      R.Version()\$version.string
    \$\$ LANGUAGE 'plcontainer';" \
    || die "Failed to create PL/Container R function"

  psql -d gpadmin -c "SELECT test_container_r_version();" || die "Failed to execute PL/Container R function"
fi

if [[ "$INSTALLED_PLCONTAINER_PY" == "true" ]]; then
  psql -d gpadmin -c "CREATE FUNCTION test_container_py_version() RETURNS text AS \$\$
      # container: plc_py
      import sys
      return sys.version
    \$\$ LANGUAGE 'plcontainer';" \
    || die "Failed to create PL/Container Python function"

  psql -d gpadmin -c "SELECT test_container_py_version();" || die "Failed to execute PL/Container Python function"
fi

if [[ "$INSTALLED_MADLIB" == "true" ]]; then
  psql -d gpadmin -c "SELECT madlib.version();" || die "Failed to install MADlib"
fi
