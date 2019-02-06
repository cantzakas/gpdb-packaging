#!/bin/bash
set -ex

sudo mv ~/plc-py.tar.gz /home/gpadmin
sudo chown gpadmin:gpadmin /home/gpadmin/plc-py.tar.gz

sudo -i -u gpadmin <<'EOF'
set -ex

plcontainer image-add -f ~/plc-py.tar.gz

rm ~/plc-py.tar.gz

plcontainer runtime-add -r plc_py -i pivotaldata/plcontainer_python_shared:devel -l python

EOF
