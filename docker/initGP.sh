#!/bin/bash

#/usr/sbin/sshd

source /usr/local/greenplum-db/greenplum_path.sh
export MASTER_DATA_DIRECTORY=/gpmaster/gpsne-1
export USER=gpadmin
export LOGNAME=gpadmin

gpinitsystem -c gpinitsystem_singlenode