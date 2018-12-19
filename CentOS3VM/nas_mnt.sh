#!/bin/bash
set -e
PKGS=$(dirname $(readlink -f "$0") )
source $PKGS/pgCluster.env

# Set Default paths
[ -z "$nas_srv_path" ] && nas_srv_path=/opt/ps_nas
[ -z "$arc_path" ] && arc_path=/mnt/ps_nas

yum -y install nfs-utils libnfsidmap
systemctl enable rpcbind 2>/dev/null
systemctl start  rpcbind
showmount -e $nas_ip

#Mounting NAS OnClient
mkdir -p $arc_path
echo "# NAS Mount for PostgreSQL 
$nas_ip:$nas_srv_path $arc_path nfs rw,sync,hard,intr 0 0" >> /etc/fstab

mount -a
