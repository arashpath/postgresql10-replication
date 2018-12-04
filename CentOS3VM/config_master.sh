#!/bin/bash
set -e
PKGS=$(dirname $(readlink -f "$0") )

echo "
################################################################################
#                          Setup as Master Server                              #
################################################################################
"
source $PKGS/pgCluster.env

# Get PostgreSQL DATA directory -----------------------------------------------#
QUERY="SELECT setting FROM pg_settings WHERE name = 'data_directory';"
PGDATA=$(sudo -u postgres -- psql -Atc "$QUERY" 2> /dev/null)
echo $PGDATA

# Genetating pg_ssl Keys ------------------------------------------------------#
echo "Configuring SSL Connection..."
openssl genrsa 4096 > $PGDATA/server.key 2> /dev/null
openssl req -new -sha256 \
    -key $PGDATA/server.key \
    -subj "/C=IN/ST=NewDelhi/O=FSSAI/OU=IT
    /CN=fssai.gov.in" >  $PGDATA/server.csr 2> /dev/null
openssl x509 -req -days 3650 \
    -in $PGDATA/server.csr \
    -signkey $PGDATA/server.key \
    -out $PGDATA/server.crt 2> /dev/null
chmod 600 $PGDATA/server.*
chown postgres.postgres $PGDATA/server.*
sed -i '/ssl = off/s/^#ssl = off/ssl = on/
/ssl_cert_file/s/^#//
/ssl_key_file/s/^#//
' $PGDATA/postgresql.conf

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

# postgresql.conf -------------------------------------------------------------#
sed -i "/wal_level =/s/^.*$/wal_level = replica/
/max_wal_senders =/ {
    s/^#//
    s/max_wal_senders = .*/max_wal_senders = 3/
}
/wal_keep_segments =/ {
    s/^#//
    s/wal_keep_segments = .*/wal_keep_segments = 32/
}
/hot_standby = on/ {
    s/^#//
}
" $PGDATA/postgresql.conf

# Creating Replication Role and Permission ------------------------------------#
echo "Configuring Replication..."
REP_SLOT="set password_encryption = 'scram-sha-256';
    CREATE ROLE $r_user WITH REPLICATION LOGIN PASSWORD '$r_pass';
    SELECT pg_create_physical_replication_slot('replslot1');"
sudo -u postgres -H -- psql -c "$REP_SLOT" 2> /dev/null

# Editing pg_hba.conf ---------------------------------------------------------#
sed -i "/# replication privilege/a\
hostssl  replication    replrole        $psql01/32      scram-sha-256 \n\
hostssl  replication    replrole        $psql02/32      scram-sha-256 \
" $PGDATA/pg_hba.conf

# Creating recovery.done ------------------------------------------------------#
conninfo="host=$psql02 port=5432 user=$r_user password=$r_pass sslmode=require"
cat <<EOF > $PGDATA/recovery.done
standby_mode      = 'on'
primary_conninfo  = '$conninfo'
trigger_file      = '/tmp/MasterNow'
primary_slot_name = 'replslot1'
restore_command   = 'cp $nas_arc_path/$HOSTNAME/%f "%p"'
EOF
chown postgres.postgres $PGDATA/recovery.done

# Restart Server --------------------------------------------------------------#
systemctl restart postgresql-10
echo "
######################### Server Configured as Master ##########################
"
