#!/bin/bash

set -e
# Update Source list
sudo apt-get update
#Install PostgreSQL 10 cluster
sudo apt-get install -y postgresql-10

#Locations
arc_loc=/var/lib/postgresql/pg_log_archive
conf_loc=/etc/postgresql/10/

#Creating Archive Directories
sudo -H -u postgres mkdir -p $arc_loc/{main,replica1}

# Configuring Master ----------------------------------------------------------#
echo "Configuring Master"
archive_cmd="archive_command = 'test ! -f $arc_loc/main/%f && cp %p $arc_loc/main/%f'"

sudo sed -i "/wal_level = /s/^.*$/wal_level = replica/
/wal_log_hints = /s/^.*$/wal_log_hints = on/
/archive_mode =/ {
    s/^#//
    s/ = off/ = on/
}
/archive_command =/ {
    i$archive_cmd
}
/max_wal_senders = /s/^.*$/max_wal_senders = 10/
/wal_keep_segments = /s/^.*$/wal_keep_segments = 64/
/hot_standby = on/ {
    s/^#//
}
" $conf_loc/main/postgresql.conf

sudo sed -i "/# replication privilege/a\
local   replication     rep_user                                trust" $conf_loc/main/pg_hba.conf


sudo -H -u postgres psql -c "CREATE USER rep_user WITH replication;
select * from pg_create_physical_replication_slot('replica');
select * from pg_replication_slots;" 

sudo pg_ctlcluster 10 main restart

# Creating & Configuring Slave ------------------------------------------------#
echo "Configuring Slave"
sudo pg_createcluster 10 replica1 
sudo systemctl stop postgresql@10-replica1
sudo pg_lsclusters 

archive_cmd="archive_command = 'test ! -f $arc_loc/replica1/%f && cp %p $arc_loc/replica1/%f'"

sudo sed -i "/wal_level = /s/^.*$/wal_level = replica/
/wal_log_hints = /s/^.*$/wal_log_hints = on/
/archive_mode =/ {
    s/^#//
    s/ = off/ = on/
}
/archive_command =/ {
    i$archive_cmd
}
/max_wal_senders = /s/^.*$/max_wal_senders = 10/
/wal_keep_segments = /s/^.*$/wal_keep_segments = 64/
/hot_standby = on/ {
    s/^#//
}
" $conf_loc/replica1/postgresql.conf

sudo sed -i "/# replication privilege/a\
local   replication     rep_user                                trust" $conf_loc/replica1/pg_hba.conf

sudo rm -rf /var/lib/postgresql/10/replica1
sudo su postgres -c 'pg_basebackup -D /var/lib/postgresql/10/replica1 -U rep_user -w -P' # -R create recovery.conf # -X stream 

sudo su postgres -c "cat <<EOF > /var/lib/postgresql/10/replica1/recovery.conf
restore_command = 'cp /var/lib/postgresql/pg_log_archive/replica1/%f %p' 
recovery_target_timeline = 'latest'
standby_mode = 'on'
primary_conninfo = 'user=rep_user passfile=''/var/lib/postgresql/.pgpass'' host=''/var/run/postgresql'' port=5432 sslmode=prefer sslcompression=1 krbsrvname=postgres target_session_attrs=any'
archive_cleanup_command = 'pg_archivecleanup /var/lib/postgresql/pg_log_archive/replica1 %r'
primary_slot_name = 'replica' 
EOF"

sudo pg_ctlcluster 10 replica1 start ;
sudo tail -n 100 /var/log/postgresql/postgresql-10-replica1.log 

echo "# Server Status ======================================================= #"
sudo pg_lsclusters
