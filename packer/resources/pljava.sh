#!/bin/bash
set -ex

sudo mv ~/pljava.gppkg /home/gpadmin
sudo chown gpadmin:gpadmin /home/gpadmin/pljava.gppkg

sudo -i -u gpadmin <<'EOF'
set -ex

gppkg -i ~/pljava.gppkg -a -v
rm ~/pljava.gppkg

source "$GPHOME/greenplum_path.sh"
gpstop -r -a

psql -d template1 -c "CREATE EXTENSION 'pljava';"
EOF
