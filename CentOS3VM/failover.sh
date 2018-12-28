#!/bin/bash
set -e
source /vagrant/pgCluster.env
# DataBase Server IPs 
psql01="$psql01"
psql02="$psql02"

confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Continue? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

# Setup Password less acess ---------------------------------------------------#
setupssh() {
  # Host Entry
  if ! grep -q "# DataBase Servers" /etc/hosts; then
    echo "Creating Host Entries for DB Servers ..."
    echo "# DataBase Servers
    $psql01 psql01
    $psql02 psql02" | sudo tee -a /etc/hosts
  fi
  # SSH KeyGen
  if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Generating ssh keygen ..."
    ssh-keygen -f ~/.ssh/id_rsa -q -P ""
  fi
  # Passwdless SSH
  for srv in psql01 psql02
    do 
    ssh -o PasswordAuthentication=no  -o BatchMode=yes $srv &>/dev/null || \
      echo "Copying authorized keys to $srv ..." ; \
      cat ~/.ssh/id_rsa.pub | ssh $srv 'cat >> .ssh/authorized_keys'
  done
}

# Get PostgreSQL DATA directory -----------------------------------------------#
pgdata() { 
QUERY="SELECT setting FROM pg_settings WHERE name = 'data_directory';"
PGDATA=$(
ssh $1 <<EOF 2> /dev/null
  sudo -u postgres -- psql -Atc "$QUERY" 2> /dev/null
EOF
)
echo $PGDATA
}

# Create OR Drop Replication Slots --------------------------------------------#
create_slot() {
  CREATE_REP_SLOT="SELECT pg_create_physical_replication_slot('$2');"
  ssh $1 <<EOF 2>/dev/null
  sudo -u postgres -H -- psql -c "$CREATE_REP_SLOT"
EOF
}

drop_slot() {
  DROP_REP_SLOT="SELECT pg_drop_replication_slot('$2');"
  ssh $1 <<EOF 2>/dev/null
  sudo -u postgres -H -- psql -c "$DROP_REP_SLOT"
EOF
}

# Check Servers whether it's Master or Slave ----------------------------------#
check_cluster() {
  #Commands
  inrecovery="sudo -u postgres -H -- psql -At\
              -c 'select pg_is_in_recovery();' 2> /dev/null"
  if   [[ $(ssh $psql01 "$inrecovery") == 'f' \
    &&    $(ssh $psql02 "$inrecovery") == 't' ]]; then
      master=$psql01 ; slave=$psql02
  elif [[ $(ssh $psql01 "$inrecovery") == 't' \
    &&    $(ssh $psql02 "$inrecovery") == 'f' ]]; then
      master=$psql02 ; slave=$psql01
  else 
    echo "ERROR: Some Something is Wrong." 
  fi
  echo "Master : $master"
  echo "Slave  : $slave"
}

# FailOver servers ------------------------------------------------------------#
failover() {
  #Commands
     stop="sudo systemctl stop  postgresql-10"
    start="sudo systemctl start postgresql-10" 
      log="sudo tail -20  $PGDATA/log/postgresql-$(date +%a).log"
  promote="sudo touch /tmp/pg_failover_trigger"
   demote="sudo mv -v $PGDATA/recovery.{done,conf}"
  
  echo -e "\n $master: Stopping Master ..."
  ssh $master "$stop"
  echo -e "\n $slave:  Promoting Slave ..."
  ssh $slave  "$promote"
  create_slot $slave "replslot1" 
  ssh $slave  "$log"
  echo -e "\n $master: Demoting Master & Starting it as Slave ..."
  ssh $master "$demote"
  ssh $master "$start"
  drop_slot $master "replslot1" 
  ssh $master "$log"
}


case "$1" in
  -s)   setupssh
        ;; 
  -x)   check_cluster
        confirm && failover
        check_cluster
        ;;
  -c|*) check_cluster
        ;;
esac


#echo "
################################################################################
#             >>> Server $HOSTNAME is currently in $server mode <<<                 
################################################################################
#"