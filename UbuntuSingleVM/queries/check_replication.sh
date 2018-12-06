#!/bin/bash

# on Master
sudo -H -u postgres psql -p 5432 -c "\x" \
-c "select * from pg_stat_replication;" \
-c "select * from pg_replication_slots;"

# on Master
# - on main query to track lag in bytes
# - sending_lag could indicate heavy load on primary
# - receiving_lag could indicate network issues or replica under heavy load
# - replaying_lag could indicate replica under heavy load
sudo -H -u postgres psql -p 5432 -c "\x" \
-c "select
      pid,
      application_name,
      pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn) sending_lag,
      pg_wal_lsn_diff(sent_lsn, flush_lsn) receiving_lag,
      pg_wal_lsn_diff(flush_lsn, replay_lsn) replaying_lag,
      pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) total_lag
    from pg_stat_replication;"
# on Master
sudo -H -u postgres psql -p 5432 -c "\x" \
-c "select pg_walfile_name(pg_current_wal_lsn());"

# on Slave
sudo -H -u postgres psql -p 5433 -c "\x" 
-c "SELECT
      CASE
        WHEN pg_last_wal_receive_lsn() = pg_last_wal_replay_lsn()
      THEN 0
      ELSE EXTRACT (EPOCH FROM now() - pg_last_xact_replay_timestamp())
    END AS log_delay;"

# on Slave
sudo -H -u postgres psql -p 5433 -c "select pg_is_in_recovery();"