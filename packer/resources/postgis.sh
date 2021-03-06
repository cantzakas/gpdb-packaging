#!/bin/bash
set -ex

sudo mv ~/postgis.gppkg /home/gpadmin
sudo chown gpadmin:gpadmin /home/gpadmin/postgis.gppkg

sudo -i -u gpadmin <<'EOF'
set -ex

gppkg -i ~/postgis.gppkg -a -v
rm ~/postgis.gppkg

"$GPHOME/share/postgresql/contrib/postgis-2.1/postgis_manager.sh" template1 install
EOF
