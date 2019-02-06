#!/bin/bash
set -ex

sudo mv ~/plr.gppkg /home/gpadmin
sudo chown gpadmin:gpadmin /home/gpadmin/plr.gppkg

sudo -i -u gpadmin <<'EOF'
set -ex

gppkg -i ~/plr.gppkg -a -v
rm ~/plr.gppkg

source "$GPHOME/greenplum_path.sh"
gpstop -r -a

psql -d template1 -c "CREATE LANGUAGE 'plr';"
psql -d template1 -f "$GPHOME/share/postgresql/extension/plr.sql"
EOF
