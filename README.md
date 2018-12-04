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

## [See Docs](https://github.com/arashpath/postgresql10-replication/wiki)

## References
- [Streaming replication](https://snippets.aktagon.com/snippets/824-postgresql-10-with-streaming-replication-and-pitr)
- [Monitoring replication](https://pgdash.io/blog/monitoring-postgres-replication.html)

----
## Progress Status
- [x] Create Master-Slave :heavy_check_mark:
- [x] Promote Slave on Master failure :heavy_check_mark:
- [ ] Demote old Master as Slave :heavy_check_mark:
  - [ ] Simple `recovery.conf` method :x:
  - [ ] `pg_rewind` method :zzz:
  - [x] New Base Backup :heavy_check_mark:
- [ ] [Testing scenarios with Single VM approach](../UbuntuSingleVM/UbuntuSingleVM) 
  - [x] [Create and Verify Replication](./UbuntuSingleVM/#testing-replication) :heavy_check_mark:
    - [x] Testing Without Replication Slot
      - [x] [Testing FailOver](../UbuntuSingleVM/UbuntuSingleVM#testing-failover) :heavy_check_mark:
      - [x] [Testing FailBack](../UbuntuSingleVM/UbuntuSingleVM#testing-failover) :heavy_check_mark:
    - [ ] Testing With Replication Slot
      - [ ] [Testing FailOver](../UbuntuSingleVM/UbuntuSingleVM#testing-failover) :zzz:
      - [ ] [Testing FailBack](../UbuntuSingleVM/UbuntuSingleVM#testing-failover) :zzz:
