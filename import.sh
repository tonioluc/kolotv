# 1 - Entrer dans le conteneur Oracle
docker exec -it oracle-db bash

# 2 - Se connecter à SQL*Plus en tant qu'utilisateur SYSTEM
sqlplus system/oracle

# 2.1 - Ajouter l utilisateur kolotv
CREATE USER kolotv IDENTIFIED BY kolotv;
GRANT CONNECT, RESOURCE, DBA TO kolotv;
ALTER USER kolotv DEFAULT TABLESPACE USERS;
ALTER USER kolotv TEMPORARY TABLESPACE TEMP;
exit;
exit;   

# 3 - Importer le fichier .dmp dans la base de données Oracle
docker cp export_20260122.dmp oracle-db:/home/oracle/

# 4 - Entrer à nouveau dans le conteneur Oracle pour lancer l'importation
docker exec -it oracle-db bash

# 5 - Lancer l'importation avec imp
imp kolotv/kolotv file=/home/oracle/export_20260122.dmp full=yes ignore=yes