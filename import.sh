# 1 - Entrer dans le conteneur Oracle
docker exec -it oracle-db bash

# 2 - Se connecter à SQL*Plus en tant qu'utilisateur SYSTEM
sqlplus system/oracle
CREATE USER kolotv IDENTIFIED BY kolotv;
GRANT CONNECT, RESOURCE, DBA TO kolotv;
ALTER USER kolotv DEFAULT TABLESPACE USERS;
ALTER USER kolotv TEMPORARY TABLESPACE TEMP;
exit;
exit;   

# 3 - Importer le fichier .dmp dans la base de données Oracle
# (n'oubliez pas de modifier le chemin du fichier .dmp , le mien est dans /home/antonio/ITU/S5/mr-tahina/kolotv/export_20260122.dmp)
docker cp /home/antonio/ITU/S5/mr-tahina/kolotv/export_20260122.dmp oracle-db:/home/oracle/

# 4 - Entrer à nouveau dans le conteneur Oracle pour lancer l'importation
docker exec -it oracle-db bash

# 5 - Lancer l'importation avec imp
imp kolotv/kolotv file=/home/oracle/export_20260122.dmp full=yes ignore=yes