#!/bin/bash
set -ex

sudo mv ~/plc-r.tar.gz /home/gpadmin
sudo chown gpadmin:gpadmin /home/gpadmin/plc-r.tar.gz

sudo -i -u gpadmin <<'EOF'
set -ex

plcontainer image-add -f ~/plc-r.tar.gz

rm ~/plc-r.tar.gz

plcontainer runtime-add -r plc_r -i pivotaldata/plcontainer_r_shared:devel -l r

EOF
