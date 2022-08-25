#!/bin/bash
SCRIPT=~/Programming/devops/scripts/virt-install.sh

$SCRIPT mycluster-cp1 192.168.122.191 2 2048 30
$SCRIPT mycluster-cp2 192.168.122.192 2 2048 30
$SCRIPT mycluster-cp3 192.168.122.193 2 2048 30
$SCRIPT mycluster-w1 192.168.122.194 1 2048 30
$SCRIPT mycluster-w2 192.168.122.195 1 2048 30
$SCRIPT mycluster-w3 192.168.122.196 1 2048 30
#$SCRIPT mycluster-w4 192.168.122.197 1 2048 30
