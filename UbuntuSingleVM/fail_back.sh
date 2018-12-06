#!/bin/bash
set -e
echo "Current State"
sudo pg_lsclusters

# Location
arc_loc=/var/lib/postgresql/pg_log_archive
conf_loc=/etc/postgresql/10/

echo "Stopping Master: replica1 ..."
sudo pg_ctlcluster 10 replica1 stop

echo "Promote Slave: main ..."
sudo pg_ctlcluster 10 main promote
sudo tail -n 20 /var/log/postgresql/postgresql-10-main.log

echo "Creating recovery.conf for: replica1 "
sudo mv /var/lib/postgresql/10/replica1/recovery.done \
    /var/lib/postgresql/10/replica1/recovery.conf

echo "Creating replication slot"
sudo -H -u postgres psql -p 5432 -c "select * 
from pg_create_physical_replication_slot('replica');"

# Starting Main As Slave
echo "Deomote Master..."
sudo systemctl start postgresql@10-replica1
sudo tail -n 20 /var/log/postgresql/postgresql-10-replica1.log

# review and drop slots on replica
sudo -H -u postgres psql -p 5433 -c "select * from pg_replication_slots;"
sudo -H -u postgres psql -p 5433 -c "select * from pg_drop_replication_slot('main');"


sudo pg_lsclusters

