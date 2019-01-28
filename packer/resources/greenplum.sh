#!/bin/bash

set -ex

DATA_DIR="/gpdata"
TEMP_DIR="/gp_tmp"
MASTER_HOSTNAME="gpdbox"

GPADMIN_PASSWORD="changeme";

install_packages() {
  if which apt; then
    sudo apt install -y "$@"
  else
    sudo yum install -y "$@"
  fi
}

echo "Installing required packages"
install_packages unzip

echo "Creating users"
sudo adduser gpadmin -p "$(echo "$GPADMIN_PASSWORD" | openssl passwd -stdin)"

echo "Unzipping Greenplum"
mkdir -p ~/gp
unzip ~/greenplum.zip -d ~/gp
rm ~/greenplum.zip

echo "Installing Greenplum"
BINFILE=( ~/gp/greenplum-db-*.bin )
sed -i 's/more << EOF/cat << EOF/g' "$BINFILE"
echo -e "yes\n\nyes\nyes\n" | sudo "$BINFILE"

sudo mkdir -p "$TEMP_DIR" "$DATA_DIR/master" "$DATA_DIR/segments"

sudo_append() {
  sudo tee -a "$1" >/dev/null
}

echo "Configuring system"

sudo_append /etc/sysctl.conf <<-EOF
######################
# HAWQ CONFIG PARAMS #
######################

kernel.shmmax = 1000000000
kernel.shmmni = 4096
kernel.shmall = 4000000000
kernel.sem = 250 512000 100 2048
kernel.sysrq = 1
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.msgmni = 2048
net.ipv4.tcp_syncookies = 0
net.ipv4.ip_forward = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_max_syn_backlog = 200000
net.ipv4.conf.all.arp_filter = 1
net.ipv4.ip_local_port_range = 1025 65535
net.core.netdev_max_backlog = 200000
fs.nr_open = 3000000
kernel.threads-max = 798720
kernel.pid_max = 798720
net.core.rmem_max=2097152
net.core.wmem_max=2097152
vm.overcommit_memory=2
EOF

sudo_append /etc/security/limits.conf <<-EOF
######################
# HAWQ CONFIG PARAMS #
######################

* soft nofile 65536
* hard nofile 65536
* soft nproc 131072
* hard nproc 131072
EOF

sudo_append /home/gpadmin/.bashrc <<-EOF
# Add GPDB custom variables
source /usr/local/greenplum-db/greenplum_path.sh
# source /usr/local/greenplum-cc-web/gpcc_path.sh
export MASTER_DATA_DIRECTORY="${DATA_DIR}/master/gpseg-1"

EOF

sudo_append /home/gpadmin/.bash_profile <<-EOF
# Set the PS1 prompt (with colors).
# Based on http://www-128.ibm.com/developerworks/linux/library/l-tip-prompt/
# And http://networking.ringofsaturn.com/Unix/Bash-prompts.php .
PS1="\[\e[36;1m\]\u@\h:\[\e[32;1m\]\w$ \[\e[0m\]"

# Add GPDB custom variables
source /usr/local/greenplum-db/greenplum_path.sh
# source /usr/local/greenplum-cc-web/gpcc_path.sh
export MASTER_DATA_DIRECTORY="${DATA_DIR}/master/gpseg-1"

EOF

sudo_append /home/gpadmin/start_all.sh <<-EOF
echo "*********************************************************************************"
echo "* Script starts the Greenplum DB                                                *"
# echo "  , Greenplum Control Center, and Apache Zeppelin *"
echo "*********************************************************************************"
echo "* Starting Greenplum Database...                                                *"
source /usr/local/greenplum-db/greenplum_path.sh
export MASTER_DATA_DIRECTORY="${DATA_DIR}/master/gpseg-1"
gpstart -a
echo "*********************************************************************************"
echo "* Pivotal Greenplum Database Started on port 5432                               *"
echo "*********************************************************************************"
echo;echo
EOF

sudo_append /home/gpadmin/stop_all.sh <<-EOF
echo "********************************************************************************************"
echo "* This script stops the Greenplum Database.                                                *"
echo "********************************************************************************************"
echo "* Stopping Greenplum Database..."
source /usr/local/greenplum-db/greenplum_path.sh
export MASTER_DATA_DIRECTORY="${DATA_DIR}/master/gpseg-1"
gpstop -M immediate -a
echo "* Greenplum Database Stopped.                                                              *"
echo "********************************************************************************************"
echo "* ALL DATABASE RELATED SERVICES STOPPED.    RUN ./start_all.sh to restart                  *"
echo "********************************************************************************************"
echo;
EOF

sudo chown gpadmin:gpadmin /home/gpadmin/.bashrc /home/gpadmin/.bash_profile /home/gpadmin/start_all.sh /home/gpadmin/stop_all.sh
sudo chmod 0744 /home/gpadmin/.bashrc /home/gpadmin/.bash_profile
sudo chmod +x /home/gpadmin/start_all.sh /home/gpadmin/stop_all.sh

echo "Configuring Greenplum"

sudo_append "$TEMP_DIR/gpinitsystem.single_node" <<-EOF
# FILE NAME: gpinitsystem_singlenode

# A configuration file is needed by the gpinitsystem utility.
# This sample file initializes a Greenplum Database Single Node
# Edition (SNE) system with one master and  two segment instances
# on the local host. This file is referenced when you run gpinitsystem.

################################################
# REQUIRED PARAMETERS
################################################

# A name for the array you are configuring. You can use any name you
# like. Enclose the name in quotes if the name contains spaces.

ARRAY_NAME="GREENPLUM SANDBOX"


# This specifies the file that contains the list of segment host names
# that comprise the Greenplum system. For a single-node system, this
# file contains the local OS-configured hostname (as output by the
# hostname command). If the file does not reside in the same
# directory where the gpinitsystem utility is executed, specify
# the absolute path to the file.

MACHINE_LIST_FILE="${TEMP_DIR}/gpdb-hosts"


# This specifies a prefix that will be used to name the data directories
# of the master and segment instances. The naming convention for data
# directories in a Greenplum Database system is SEG_PREFIX<number>
# where <number> starts with 0 for segment instances and the master
# is always -1. So for example, if you choose the prefix gpsne, your
# master instance data directory would be named gpsne-1, and the segment
# instances would be named gpsne0, gpsne1, gpsne2, gpsne3, and so on.

SEG_PREFIX=gpseg


# Base port number on which primary segment instances will be
# started on a segment host. The base port number will be
# incremented by one for each segment instance started on a host.

PORT_BASE=40000


# This specifies the data storage location(s) where the script will
# create the primary segment data directories. The script creates a
# unique data directory for each segment instance. If you want multiple
# segment instances per host, list a data storage area for each primary
# segment you want created. The recommended number is one primary segment
# per CPU. It is OK to list the same data storage area multiple times
# if you want your data directories created in the same location. The
# number of data directory locations specified will determine the number
# of primary segment instances created per host.
# You must make sure that the user who runs gpinitsystem (for example,
# the gpadmin user) has permissions to write to these directories. You
# may want to create these directories on the segment hosts before running
# gpinitsystem and chown them to the appropriate user.

declare -a DATA_DIRECTORY=(${DATA_DIR}/segments ${DATA_DIR}/segments)

# The OS-configured hostname of the Greenplum Database master instance.

MASTER_HOSTNAME=${MASTER_HOSTNAME}

# The location where the data directory will be created on the
# Greenplum master host.
# You must make sure that the user who runs gpinitsystem
# has permissions to write to this directory. You may want to
# create this directory on the master host before running
# gpinitsystem and chown it to the appropriate user.

MASTER_DIRECTORY=${DATA_DIR}/master


# The port number for the master instance. This is the port number
# that users and client connections will use when accessing the
# Greenplum Database system.

MASTER_PORT=5432

# The shell the gpinitsystem script uses to execute
# commands on remote hosts. Allowed value is ssh. You must set up
# your trusted host environment before running the gpinitsystem
# script. You can use gpssh-exkeys to do this.

TRUSTED_SHELL=ssh

# Maximum distance between automatic write ahead log (WAL)
# checkpoints, in log file segments (each segment is normally 16
# megabytes). This will set the checkpoint_segments parameter
# in the postgresql.conf file for each segment instance in the
# Greenplum Database system.

CHECK_POINT_SEGMENTS=8

# The character set encoding to use. Greenplum supports the
# same character sets as PostgreSQL. See 'Character Set Support'
# in the PostgreSQL documentation for allowed character sets.
# Should correspond to the OS locale specified with the
# gpinitsystem -n option.

ENCODING=UNICODE

################################################
# OPTIONAL PARAMETERS
################################################

# Optional. Uncomment to create a database of this name after the
# system is initialized. You can always create a database later using
# the CREATE DATABASE command or the createdb script.

DATABASE_NAME=gpadmin

MASTER_MAX_CONNECT=250
EOF

sudo_append "$TEMP_DIR/gpdb-hosts" <<-EOF
${MASTER_HOSTNAME}
EOF

sudo_append /etc/hosts <<-EOF
127.0.0.1 ${MASTER_HOSTNAME}
EOF

sudo chown -R gpadmin:gpadmin "$TEMP_DIR" "$DATA_DIR"
sudo chmod 666 "$TEMP_DIR"/*

echo "Creating database"

sudo su gpadmin -c "
set -ex
cd ~
source ~/.bashrc

gpssh-exkeys -f '$TEMP_DIR/gpdb-hosts'
ssh-keyscan -H '$MASTER_HOSTNAME' >> ~/.ssh/known_hosts
ssh-keyscan -H 'localhost.localdomain' >> ~/.ssh/known_hosts

# gpinitsystem returns non-zero even on success, so this could silently fail and continue!
gpinitsystem -a -c '$TEMP_DIR/gpinitsystem.single_node' || true
psql -d template1 -c \"alter user gpadmin password 'pivotal';\"
"

sudo_append "$DATA_DIR/master/gpseg-1/pg_hba.conf" <<-EOF
host all all 0.0.0.0/0 md5
EOF

sudo su gpadmin -l -c "gpstop -u && psql -d gpadmin -c 'SELECT version();'"

echo "Cleaning up"
sudo rm -rf "$TEMP_DIR"
rm -rf ~/gp

echo "Assigning sudo rights to gpadmin"
sudo /bin/bash -c 'echo "gpadmin ALL=(ALL) ALL" >> /etc/sudoers.d/gpadmin; chmod 0440 /etc/sudoers.d/gpadmin'

echo "Done."
