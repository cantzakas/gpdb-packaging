#!/bin/bash
set -ex

sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum makecache fast
sudo yum install -y docker-ce
sudo systemctl start docker
sudo usermod -aG docker gpadmin

sudo systemctl start docker.service

sudo mv ~/plcontainer.gppkg ~/plc-r.tar.gz ~/plc-py.tar.gz /home/gpadmin
sudo chown gpadmin:gpadmin /home/gpadmin/plcontainer.gppkg /home/gpadmin/plc-r.tar.gz /home/gpadmin/plc-py.tar.gz

sudo -i -u gpadmin <<'EOF'
set -ex

gppkg -i ~/plcontainer.gppkg
source $GPHOME/greenplum_path.sh
gpstop -ra

psql -d template1 -c 'CREATE EXTENSION plcontainer;'

plcontainer image-add -f ~/plc-r.tar.gz
plcontainer image-add -f ~/plc-py.tar.gz

rm ~/plc-*.tar.gz

plcontainer image-list

plcontainer runtime-add -r plc_r -i pivotaldata/plcontainer_r_shared:devel -l r
plcontainer runtime-add -r plc_py -i pivotaldata/plcontainer_python_shared:devel -l python

EOF
