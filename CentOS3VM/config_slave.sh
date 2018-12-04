#!/bin/bash
set -e
PKGS=$(dirname $(readlink -f "$0") )

echo "
################################################################################
#                          Setup as Slave Server                               #
################################################################################
"
source $PKGS/pgCluster.env

# Get PostgreSQL DATA directory -----------------------------------------------#
QUERY="SELECT setting FROM pg_settings WHERE name = 'data_directory';"
PGDATA=$(sudo -u postgres -- psql -Atc "$QUERY" 2> /dev/null)
echo $PGDATA

# Creating new base backup ----------------------------------------------------#
echo "Creating new base backup..."
systemctl stop postgresql-10
rm -rf $PGDATA
PGPASSWORD=$r_pass \
pg_basebackup -h $psql01 -D $PGDATA -P -U $r_user -X stream 2>/dev/null
chown -R postgres.postgres $PGDATA

# Setting Up Archiving --------------------------------------------------------#
echo "Configuring Archiving..."
mkdir -p $nas_arc_path/$HOSTNAME
chown -R postgres.postgres $nas_arc_path/$HOSTNAME
archive_cmd="archive_command = 'test ! -f $nas_arc_path/$HOSTNAME/%f \&\& \
  cp %p $nas_arc_path/$HOSTNAME/%f'"
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
standby_mode      = 'on'
primary_conninfo  = '$conninfo'
trigger_file      = '/tmp/MasterNow'
primary_slot_name = 'replslot1'
restore_command   = 'cp $nas_arc_path/$HOSTNAME/%f "%p"'
EOF
chown postgres.postgres $PGDATA/recovery.conf

# Restart Server --------------------------------------------------------------#
systemctl restart postgresql-10
echo "
######################### Server Configured as Slave ###########################
"
