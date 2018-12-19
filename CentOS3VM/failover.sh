#!/bin/bash
set -e
function check_srv() {
  recovery=$(sudo -u postgres -H -- psql -At\
      -c "select pg_is_in_recovery();" 2> /dev/null)
  if [ "$recovery" == "f" ]; 
    then server="MASTER"
  elif [ "$recovery" == "t" ]; 
    then server="SLAVE"
  fi
}
check_srv
echo "
################################################################################
             >>> Server $HOSTNAME is currently in $server mode <<<                 
################################################################################
"

#M SELECT pg_reload_conf();

#M systemctl stop postgresql-10

#S touch /tmp/pg_failover_trigger
#S SELECT pg_create_physical_replication_slot('replslot1');

#M mv /opt/psqlDATA/recovery.{done,conf}
#M systemctl start postgresql-10
#M select pg_drop_replication_slot('replslot1');
sudo tail -100  /opt/psqlDATA/log/postgresql-$(date +%a).log

