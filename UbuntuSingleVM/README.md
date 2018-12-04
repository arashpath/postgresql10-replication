[![Build Status](https://travis-ci.org/arashpath/postgresql10-replication.svg?branch=UbuntuSingleVM)](https://travis-ci.org/arashpath/postgresql10-replication)
# Testing scenarios with Single VM approach - Ubuntu 
To avoid complication of multiple vms and nas we lets test on a single vm

## Progress Status
- [x] [Create and Verify Replication](#testing-replication) :heavy_check_mark:
- [x] Testing Without Replication Slot :heavy_check_mark:
  - [x] [Testing FailOver](#testing-failover) 
  - [x] [Testing FailBack](#testing-failback) 
- [x] Testing With Replication Slot :heavy_check_mark:
  - [x] [Testing FailOver](#testing-failover) 
  - [x] [Testing FailBack](#testing-failback)


## Tutorials
- [Streaming Replication](https://www.scalingpostgres.com/tutorials/postgresql-streaming-replication/)
- [Replication Slots](https://www.scalingpostgres.com/tutorials/postgresql-replication-slots/)

## Setup
```
git clone https://github.com/arashpath/postgresql10-replication.git
cd postgresql10-replication
git checkout UbuntuSingleVM
cd UbuntuSingleVM
vagrant up
```

## Testing
### Testing Replication
* login to server
`vagrant ssh`
* Create DB and insert data on main
```
# create database with some data
sudo -H -u postgres psql -p 5432 -c "create database test;" 
sudo -H -u postgres psql -p 5432 test -c " 
  create table test_table ( 
    id integer, 
    title character varying(100), 
    comments text, 
    insert_time timestamp without time zone, 
    master character varying(100) 
  );   
  insert into test_table (id, title, comments, insert_time, master) values 
    (100, 'Data Created', 'Main as Master', now(), 'main'), 
    (101, 'Testing Replication', 'should replicate on replica1', now(), 'main');
  "
# verify data has been replicated on replica
sudo -H -u postgres psql -p 5432 test -c "select * from test_table;"  #Main
sudo -H -u postgres psql -p 5433 test -c "select * from test_table;"  #Replica 
```

### Testing FailOver
* Login and run fail-over script
  - `sh /vagrant/fail_over.sh` 
* Insert some data in Replica
```
# Insert data in replica1 (Current master)
sudo -H -u postgres psql -p 5433 test -c "insert into test_table 
  (id, title, comments, insert_time, master) values 
  (102, 'Testing FailOver', 'Replica1 as master', now(), 'replica1'), 
  (103, 'Testing FailOver', 'should replicate on main', now(), 'replica1');"  
# verify data has been replicated on replica
sudo -H -u postgres psql -p 5432 test -c "select * from test_table;"  #Main
sudo -H -u postgres psql -p 5433 test -c "select * from test_table;"  #Replica  
```

### Testing FailBack
* Login to VM and run fail-back script
- `sh /vagrant/fail_back.sh`
* Insert data in main
```
# Insert data in main (Current master)
sudo -H -u postgres psql -p 5432 test -c "insert into test_table 
  (id, title, comments, insert_time, master) values 
  (104, 'Testing FailBack', 'main as master', now(), 'main'), 
  (105, 'Testing FailBack', 'should replicate on replica1', now(), 'main');" 
# verify data has been replicated on replica
sudo -H -u postgres psql -p 5432 test -c "select * from test_table;"  #Main
sudo -H -u postgres psql -p 5433 test -c "select * from test_table;"  #Replica 
```