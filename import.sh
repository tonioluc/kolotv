docker exec -it oracle-db bash

sqlplus system/oracle

CREATE USER kolotv IDENTIFIED BY kolotv;
GRANT CONNECT, RESOURCE, DBA TO kolotv;
ALTER USER kolotv DEFAULT TABLESPACE USERS;
ALTER USER kolotv TEMPORARY TABLESPACE TEMP;
exit;
exit;   




docker cp /home/antonio/Bureau/S5/mr-tahina/kolotv/export_20260122.dmp oracle-db:/home/oracle/
docker exec -it oracle-db bash
imp kolotv/kolotv file=/home/oracle/export_20260122.dmp full=yes ignore=yes