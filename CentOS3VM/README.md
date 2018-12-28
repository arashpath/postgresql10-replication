# Testing with Live like Environment
CentOS7 3VMs (Master, Slave and NAS) 

## Progress Status
- :heavy_check_mark: Setup Streaming Replication
- :heavy_check_mark: Setup Replication Slots
- :heavy_check_mark: FailOver
- :heavy_check_mark: Easy FailBack
- [ ] Replication Monitoring
- [ ] FailBack with pgrewind
- [ ] WAL Archiving and Restoring
- [ ] Testing PITR using log replay

## Setup
* Setup 3VMs CentOS7 - Master, Slave & NAS
  ```
  git clone https://github.com/arashpath/postgresql10-replication.git
  cd postgresql10-replication
  git checkout CentOS3VM
  cd CentOS3VM
  vagrant up
  ```
* Password Less access from NAS 
  - `vagrant ssh nas -c "sh /vagrant/failover.sh -s"`
* Check Master & Slave IPs.
  - `vagrant ssh nas -c "sh /vagrant/failover.sh -c"`

## Testing
### Testing Replication
* Connect to __psql01__ Primary Server
  - `vagrant ssh psql01 -c 'sudo -u postgres psql'`
* Create a test DB and insert some data
  ```
  CREATE DATABASE testdb;
  \c testdb
  CREATE TABLE test_table (
    id integer,
    time timestamp without time zone,
    dbsrv character varying(100),
    title character varying(100),
    comments text
  );
  INSERT INTO test_table 
    (id,  time,  dbsrv,    title,              comments)               values
    (100, now(), 'psql01', 'DB Created',       'psql01 as Master'            ),
    (101, now(), 'psql01', 'Test Replication', 'should replicate on psql02'  );
  \q
  ```
* [Verify](#Verify) : `test\verify.bat`
### Testing FailOver
* FailOver Master(__psql01__) to Slave(__psql02__) Servers
  - `vagrant ssh nas -c "sh /vagrant/failover.sh -x"`
* Connect to __psql02__ Now Primary Server
  - `vagrant ssh psql02 -c 'sudo -u postgres psql testdb'`
* Insert some more data to verify replication
  ```
  INSERT INTO test_table
    (id,  time,  dbsrv,    title,              comments)           values
    (102, now(), 'psql02', 'Test FailOver', 'psql02 as master'         ),
    (103, now(), 'psql02', 'Test FailOver', 'should replicate on psql01' );
  \q
  ```
* [Verify](#Verify) : `test\verify.bat`
### Testing FailBack
* FailBack Master(__psql02__) to Slave(__psql01__) Servers
  - `vagrant ssh nas -c "sh /vagrant/failover.sh -x"`
* Connect to __psql01__ Now Primary Server
  - `vagrant ssh psql01 -c 'sudo -u postgres psql testdb'`
* Insert some more data to verify replication
  ```
  INSERT INTO test_table
    (id,  time,  dbsrv,    title,              comments)           values
    (104, now(), 'psql01', 'Test FailBack', 'psql01 as master'         ),
    (105, now(), 'psql01', 'Test FailBack', 'should replicate on psql02' );
  \q
  ```
* [Verify](#Verify) : `test\verify.bat`
## Verify 
  Verify if data has been present on both servers
  `test\verify.bat`
  ```
  vagrant ssh psql01 -c "sudo -u postgres psql test -c 'select * from test_table;'"
  vagrant ssh psql02 -c "sudo -u postgres psql test -c 'select * from test_table;'"
  ```

----
## References
- [Streaming replication](https://snippets.aktagon.com/snippets/824-postgresql-10-with-streaming-replication-and-pitr)
- [Monitoring replication](https://pgdash.io/blog/monitoring-postgres-replication.html)