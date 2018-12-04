# Insert data in main (Current master)
sudo -H -u postgres psql -p 5432 test -c "insert into test_table 
  (id, title, comments, insert_time, master) values 
  (104, 'Testing FailBack', 'main as master', now(), 'main'), 
  (105, 'Testing FailBack', 'should replicate on replica1', now(), 'main');" 
# verify data has been replicated on replica
sudo -H -u postgres psql -p 5432 test -c "select * from test_table;"  #Main
sudo -H -u postgres psql -p 5433 test -c "select * from test_table;"  #Replica