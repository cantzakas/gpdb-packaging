#!/bin/bash

set -ex

sudo cp ~/plr.gppkg /home/gpadmin
sudo chown gpadmin:gpadmin /home/gpadmin/plr.gppkg

sudo su gpadmin -c "
set -ex
cd ~
source ~/.bashrc

gppkg -i ~/plr.gppkg -a -v

gpstop -r -a

source \$GPHOME/greenplum_path.sh

psql -d template1 -c \"CREATE LANGUAGE 'plr';\"

psql -d template1 -f \$GPHOME/share/postgresql/extension/plr.sql
"
