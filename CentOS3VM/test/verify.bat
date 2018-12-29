vagrant ssh psql01 -c "sudo -u postgres psql testdb -c 'select * from test_table;' 2>/dev/null"
vagrant ssh psql02 -c "sudo -u postgres psql testdb -c 'select * from test_table;' 2>/dev/null"
