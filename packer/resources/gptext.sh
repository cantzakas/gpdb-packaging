#!/bin/bash
set -ex

DATA_DIR="/gpdata"
MASTER_HOSTNAME="$HOSTNAME"

sudo yum install -y nc lsof

cat <<EOF > ~/gptext-config
GPTEXT_HOSTS="ALLSEGHOSTS"
declare -a DATA_DIRECTORY=(${DATA_DIR}/primary ${DATA_DIR}/primary)

JAVA_OPTS="-Xms1024M -Xmx2048M"

GPTEXT_PORT_BASE=18983
GP_MAX_PORT_LIMIT=28983

ZOO_CLUSTER="BINDING"
declare -a ZOO_HOSTS=(${MASTER_HOSTNAME} ${MASTER_HOSTNAME} ${MASTER_HOSTNAME})
ZOO_DATA_DIR="${DATA_DIR}/master/"
ZOO_GPTXTNODE="gptext"
ZOO_PORT_BASE=2188
ZOO_MAX_PORT_LIMIT=12188
EOF

# Unzip and extract version from filename
tar xzvf ~/gptext.tar.gz -C ~
GPTEXT_VERSION="$(ls ~/greenplum-text-*.bin)"
GPTEXT_VERSION="${GPTEXT_VERSION%-*}"
GPTEXT_VERSION="${GPTEXT_VERSION##*-}"

# Create installation directories and set permissions
INSTALL_DIR="/usr/local/greenplum-text-$GPTEXT_VERSION"
sudo mkdir -p "$INSTALL_DIR" /usr/local/greenplum-solr
sudo ln -s "$INSTALL_DIR" "/usr/local/greenplum-text"

sudo chown gpadmin:gpadmin /usr/local/greenplum-text*
sudo chown gpadmin:gpadmin /usr/local/greenplum-solr*

# Move installer and configuration to gpadmin user
sudo mv ~/greenplum-text-*.bin /home/gpadmin/gptext.bin
sudo mv ~/gptext-config /home/gpadmin/
sudo chown gpadmin:gpadmin /home/gpadmin/gptext.bin /home/gpadmin/gptext-config
sudo chmod +x /home/gpadmin/gptext.bin

# Install
sudo -i -u gpadmin <<EOF
set -ex

echo -e "yes\n\nyes\nyes\n" | ~/gptext.bin -c ~/gptext-config
rm ~/gptext.bin ~/gptext-config
EOF

# Update helper scripts

sudo_append() {
  sudo tee -a "$1" >/dev/null
}

sudo_append /home/gpadmin/.bashrc <<EOF
source /usr/local/greenplum-text/greenplum-text_path.sh
EOF

sudo_append /home/gpadmin/start_all.sh <<EOF
zkManager start
gptext-start
EOF
