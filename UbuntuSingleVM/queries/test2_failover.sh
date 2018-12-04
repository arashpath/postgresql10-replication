# Insert data in replica1 (Current master)
sudo -H -u postgres psql -p 5433 test -c "insert into test_table 
  (id, title, comments, insert_time, master) values 
  (102, 'Testing FailOver', 'Replica1 as master', now(), 'replica1'), 
  (103, 'Testing FailOver', 'should replicate on main', now(), 'replica1');"  
# verify data has been replicated on replica
sudo -H -u postgres psql -p 5432 test -c "select * from test_table;"  #Main
sudo -H -u postgres psql -p 5433 test -c "select * from test_table;"  #Replica  