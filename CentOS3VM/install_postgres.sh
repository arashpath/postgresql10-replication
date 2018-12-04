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

yum -y install $pg10_url
yum -y install postgresql10-server
mkdir $datadir ; chown postgres.postgres $datadir
export PGSETUP_INITDB_OPTIONS="--pgdata=$datadir"
sed -i "/Environment=PGDATA=/ {
    s:^.*$:Environment=PGDATA=${datadir}:
}" /usr/lib/systemd/system/postgresql-10.service
sudo /usr/pgsql-10/bin/postgresql-10-setup initdb

sed -i "/listen_addresses =/ {
s/^.*$/listen_addresses = '*' /
}" $datadir/postgresql.conf

systemctl start  postgresql-10
systemctl enable postgresql-10 2>/dev/null

echo "
####################### Installed $(psql -V) #######################
"
QUERY="SELECT name, setting FROM pg_settings 
    WHERE name in  ('config_file','data_directory','hba_file' );"
sudo -u postgres -H -- psql -c "$QUERY" 2>/dev/null
