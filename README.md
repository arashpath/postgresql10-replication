# PostgreSQL 10 With Streaming Replication and PITR
[![License: PostgreSQL](https://img.shields.io/badge/license-PostgreSQL-blue.svg)](https://www.postgresql.org/about/licence/)

PostgreSQL 10 with Master-Slave Steaming replication and archival on a separate NAS server

## GOAL

```
┌────────────────────────┐
│ Web Application Layer  │ 
└─┬────────────────────┬─┘ 
Writes	             Reads
┌─┴──────┐           ┌─┴─────┐
│ Master ├>Streaming─┤ Slave │  
└─┬──────┘           └───────┘	    
  └─>> WAL archiving to Network Drive for Recovery               
```
* Master and Slave (warm standby)
    * Database replicated to slave server via Streaming Replication
    * WAL files copied from master to a network drive
* Point-in-time-recovery (PITR) which is useful, for example, if someone deletes a table by mistake
* Recovery possible even if both master and slave are lost
* Daily and weekly backups available on a network drive
* WAL files available on a network drive
* Network drive backed up

## Progress Status
- [x] Setup __Streaming Replication__ with replication slot :heavy_check_mark:
- [x] Planned __Failover and Failback__ using `recovery.conf` method :heavy_check_mark:
- [x] __Fresh Base Backup__ methord in case of Master or Slave Crash :heavy_check_mark:
- [x] `pg_rewind` method 
- [x] Create Failover / Failback Scripts :heavy_check_mark:
- [ ] BackUp and Restore with archiving :zzz: 
- [ ] Point-in-time-recovery (PITR) :zzz:

----
### Test Branches
- Live Scenario [CentOS3VM](../CentOS3VM/CentOS3VM)
- Test Scenario [UbuntuSingleVM](../UbuntuSingleVM/UbuntuSingleVM)
[![Build Status](https://travis-ci.org/arashpath/postgresql10-replication.svg?branch=UbuntuSingleVM)](https://travis-ci.org/arashpath/postgresql10-replication)
