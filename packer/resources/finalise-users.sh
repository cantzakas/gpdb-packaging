#!/bin/bash
set -ex

# This script runs as root

echo "Assigning sudo rights to gpadmin"
echo "gpadmin ALL=(ALL) ALL" >> /etc/sudoers.d/gpadmin
chmod 0440 /etc/sudoers.d/gpadmin

rm -rf /home/configuser/*
