docker exec -it oracle-db bash

sqlplus system/oracle

CREATE USER kolotv IDENTIFIED BY kolotv;
GRANT CONNECT, RESOURCE, DBA TO kolotv;
ALTER USER kolotv DEFAULT TABLESPACE USERS;
ALTER USER kolotv TEMPORARY TABLESPACE TEMP;
exit;
exit;   




docker cp /home/antonio/ITU/S5/mr-tahina/kolotv/kolo0107.dmp oracle-db:/home/oracle/
docker exec -it oracle-db bash
imp kolotv/kolotv file=/home/oracle/kolo0107.dmp full=yes ignore=yes