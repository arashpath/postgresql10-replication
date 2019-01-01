#!/bin/bash
set -e
PKGS=$(dirname $(readlink -f "$0") )
source $PKGS/pgCluster.env
echo "
################################################################################
#                           Installing Postgresql                              #
################################################################################
"
pg10_url="https://download.postgresql.org/pub/repos/yum/10/redhat/\
rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm"

echo "Adding PostgreSQL-10 Repo ..."
yum -y install $pg10_url 1>/dev/null
echo "Installing PostgreSQL-10 ..."
yum -y install postgresql10-server postgresql10-contrib 1>/dev/null
mkdir $PGDATA ; chown postgres.postgres $PGDATA
export PGSETUP_INITDB_OPTIONS="--pgdata=$PGDATA"
sed -i "/Environment=PGDATA=/ {
    s:^.*$:Environment=PGDATA=${PGDATA}:
}" /usr/lib/systemd/system/postgresql-10.service
sudo /usr/pgsql-10/bin/postgresql-10-setup initdb

sed -i "/listen_addresses =/ {
s/^.*$/listen_addresses = '*' /
}" $PGDATA/postgresql.conf

systemctl start  postgresql-10
systemctl enable postgresql-10 2>/dev/null

echo "
####################### Installed $(psql -V) #######################
"
QUERY="SELECT name, setting FROM pg_settings 
    WHERE name in  ('config_file','data_directory','hba_file' );"
sudo -u postgres -H -- psql -tc "$QUERY" 2>/dev/null
