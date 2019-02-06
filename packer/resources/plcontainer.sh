#!/bin/bash
set -ex

sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum makecache fast
sudo yum install -y docker-ce
sudo systemctl start docker
sudo usermod -aG docker gpadmin

sudo systemctl start docker.service

sudo mv ~/plcontainer.gppkg /home/gpadmin
sudo chown gpadmin:gpadmin /home/gpadmin/plcontainer.gppkg

sudo -i -u gpadmin <<'EOF'
set -ex

gppkg -i ~/plcontainer.gppkg
source "$GPHOME/greenplum_path.sh"
gpstop -ra

psql -d template1 -c 'CREATE EXTENSION plcontainer;'

rm ~/plcontainer.gppkg

EOF
