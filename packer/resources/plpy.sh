#!/bin/bash
set -ex

sudo -i -u gpadmin <<'EOF'
set -ex

psql -d template1 -c "CREATE LANGUAGE 'plpythonu';"
EOF
