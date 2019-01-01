#!/bin/bash
set -e
PKGS=$(dirname $(readlink -f "$0") )

echo "
################################################################################
#                          Configuring Slave Server                            #
################################################################################
"
source $PKGS/pgCluster.env

# Get PostgreSQL DATA directory -----------------------------------------------#
#QUERY="SELECT setting FROM pg_settings WHERE name = 'data_directory';"
#PGDATA=$(sudo -u postgres -- psql -Atc "$QUERY" 2> /dev/null)
echo "PostgreSQL Data Directory:  $PGDATA"

# Creating new base backup ----------------------------------------------------#
echo "Creating new base backup..."
systemctl stop postgresql-10
rm -rf $PGDATA
PGPASSWORD=$r_pass \
pg_basebackup -h $psql01 -D $PGDATA -P -U $r_user -X stream 2>/dev/null
chown -R postgres.postgres $PGDATA
rm -f $PGDATA/logs/*.log
#SELECT pg_reload_conf();

# Setting Up Archiving --------------------------------------------------------#
echo "Configuring Archiving..."
mkdir -p $arc_path/$HOSTNAME
chown -R postgres.postgres $arc_path/$HOSTNAME
archive_cmd="archive_command = 'test ! -f $arc_path/$HOSTNAME/%f \&\& \
  cp %p $arc_path/$HOSTNAME/%f'"
sed -i "/archive_mode =/ {
    s/^#//
    s/ = off/ = on/
}
/archive_command =/ {
    s:^.*$:$archive_cmd:
}
" $PGDATA/postgresql.conf

# Creating recovery.conf ------------------------------------------------------#
conninfo="host=$psql01 port=5432 user=$r_user password=$r_pass sslmode=require"
cat <<EOF > $PGDATA/recovery.conf
standby_mode             = 'on'
recovery_target_timeline = 'latest'
primary_conninfo         = '$conninfo'
trigger_file             = '/tmp/pg_failover_trigger'
primary_slot_name        = 'replslot1'
restore_command          = 'cp $arc_path/$HOSTNAME/%f "%p"'
archive_cleanup_command  = 'pg_archivecleanup $arc_path/$HOSTNAME %r'
EOF
chown postgres.postgres $PGDATA/recovery.conf

# Restart Server --------------------------------------------------------------#
systemctl restart postgresql-10
echo "
######################### Server Configured as Slave ###########################
"
