#!/bin/bash
set -e
PKGS=$(dirname $(readlink -f "$0") )
source $PKGS/pgCluster.env

# Set Default paths
[ -z "$nas_srv_path" ] && nas_srv_path=/opt/ps_nas

# NAS Client
yum -y install nfs-utils libnfsidmap
systemctl enable rpcbind 2>/dev/null
systemctl start  rpcbind

# NAS Server
systemctl enable nfs-server 2>/dev/null
systemctl start  nfs-server
systemctl start  rpc-statd
systemctl start  nfs-idmapd

mkdir -p  $nas_srv_path
chmod 777 $nas_srv_path

echo "#psqlNAS
$nas_srv_path $psql01/32(rw,sync,no_root_squash)
$nas_srv_path $psql02/32(rw,sync,no_root_squash)
" > /etc/exports

exportfs -r

# Configure Firewall
#firewall-cmd --permanent --zone public --add-service mountd
#firewall-cmd --permanent --zone public --add-service rpc-bind
#firewall-cmd --permanent --zone public --add-service nfs
#firewall-cmd --reload
