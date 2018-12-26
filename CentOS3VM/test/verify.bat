vagrant ssh psql01 -c "sudo -u postgres psql testdb -c 'select * from test_table;'"
vagrant ssh psql02 -c "sudo -u postgres psql testdb -c 'select * from test_table;'"