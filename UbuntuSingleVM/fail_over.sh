#!/bin/bash
set -e
# Location
arc_loc=/var/lib/postgresql/pg_log_archive
conf_loc=/etc/postgresql/10/

echo "Stopping Master: main ..."
sudo pg_ctlcluster 10 main stop

echo "Promote Slave: replica1 ..."
sudo pg_ctlcluster 10 replica1 promote
sudo tail -n 100 /var/log/postgresql/postgresql-10-replica1.log

echo "Creating recovery.conf for: main"
sudo su postgres -c "cat <<EOF > /var/lib/postgresql/10/main/recovery.conf
restore_command = 'cp /var/lib/postgresql/pg_log_archive/main/%f %p' 
recovery_target_timeline = 'latest'
standby_mode = 'on'
primary_conninfo = 'user=rep_user passfile=''/var/lib/postgresql/.pgpass'' host=''/var/run/postgresql'' port=5433 sslmode=prefer sslcompression=1 krbsrvname=postgres target_session_attrs=any'
archive_cleanup_command = 'pg_archivecleanup /var/lib/postgresql/pg_log_archive/main %r'
primary_slot_name = 'main' 
EOF"

echo "Creating replication slot"
sudo -H -u postgres psql -c "select * from pg_create_physical_replication_slot('main');" -p 5433

# Starting Main As Slave
echo "Deomote Master: main ..."
sudo systemctl start postgresql@10-main
sudo tail -n 100 /var/log/postgresql/postgresql-10-main.log

# review and drop slots on replica
sudo -H -u postgres psql -c "select * from pg_replication_slots;"
sudo -H -u postgres psql -c "select * from pg_drop_replication_slot('replica');"

echo "Current State"
sudo pg_lsclusters
