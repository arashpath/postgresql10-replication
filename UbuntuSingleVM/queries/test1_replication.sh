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