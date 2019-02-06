#!/bin/bash
set -ex

sudo yum install -y m4

tar xzvf ~/madlib.tar.gz -C ~
sudo cp ~/madlib-*/madlib-*.gppkg /home/gpadmin/madlib.gppkg
sudo chown gpadmin:gpadmin /home/gpadmin/madlib.gppkg

sudo -i -u gpadmin <<'EOF'
set -ex

gppkg -i ~/madlib.gppkg -a -v

$GPHOME/madlib/bin/madpack -s madlib -p greenplum -c gpadmin@localhost:5432/template1 install

EOF
