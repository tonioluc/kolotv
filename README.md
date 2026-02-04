# KoloTV - Instructions d'installation

Ce document décrit, pas à pas et de manière professionnelle, la procédure pour lancer le projet KoloTV en local avec Docker.

**Prérequis**
- Docker et Docker Compose installés sur la machine.
- Espace disque suffisant pour les images Docker et l'import de la base.

**Étapes**

1) Télécharger les fichiers manquants
- Le répertoire `build-file` et le fichier `build.xml` sont exclus du dépôt (gitignore). Téléchargez-les depuis le lien fourni par l'auteur et placez-les à la racine du clone du projet.
- Collez le lien de téléchargement ici : https://drive.google.com/drive/folders/1vl0qd3sZB0N3AEcz6V6mizDEMwFRQ83-?usp=sharing

2) Copier les fichiers dans le projet
- Après téléchargement, copiez le dossier `build-file` et le fichier `build.xml` à la racine du dépôt cloné (même niveau que ce fichier README).

3) Pré-puller les images Docker nécessaires
- Afin de pouvoir construire les images sans connexion internet ultérieurement, récupérez localement les images suivantes :

  ```bash
  docker pull loliconneko/oracle-ee-11g:latest
  docker pull frekele/ant:1.10-jdk8
  docker pull jboss/wildfly:10.1.0.Final
  ```

4) Construire les images du projet
- Ouvrez un terminal dans la racine du projet (contenant `docker-compose.yml`).
- Lancez la commande suivante pour construire les images :

  ```bash
  docker compose build
  ```

5) Démarrer les services
- Si la construction termine avec succès, démarrez les services :

  - En mode attaché (affiche les logs dans le terminal) :

    ```bash
    docker compose up
    ```

  - En mode détaché (exécute en arrière-plan) :

    ```bash
    docker compose up -d
    ```

- Pour suivre les logs en détaché :

  ```bash
  docker compose logs -f
  ```

- Remarque : l'initialisation de la base Oracle peut prendre du temps ; elle est habituellement la dernière à terminer.

6) Vérifier que la base Oracle est prête
- À la fin de l'initialisation vous devriez voir un message similaire à :

  ```text
  Database ready to use. Enjoy! ;)
  ```

7) Importer les données
- L'import des données est guidé dans le fichier [import.sh](import.sh). Le script contient des commentaires décrivant chaque étape.
- Procédure synthétique :

  1. Copier le fichier `.dmp` dans le conteneur Oracle (expliqué dans `import.sh`).
  2. Se connecter au conteneur Oracle et lancer `imp kolotv/kolotv file=/home/oracle/export_20260122.dmp full=yes ignore=yes` (ou la commande indiquée dans `import.sh`).

- L'import peut durer plusieurs minutes. À la fin vous devriez voir :

  ```text
  Import terminated successfully with warnings.
  ```

- Les warnings sont généralement sans conséquence et peuvent être ignorés. NE QUITTEZ PAS encore le conteneur tant que les étapes de debug ne sont pas exécutées.

8) Exécuter le script de debug SQL
- Entrez dans `sqlplus` avec l'utilisateur :

  ```text
  sqlplus kolotv/kolotv
  ```

- Copiez et collez le contenu du fichier [debug.sql](debug.sql) dans la session `sqlplus` et validez.
- Une fois terminé, sortez du conteneur avec deux `exit` successifs si nécessaire.

9) Tester l'application
- Ouvrez votre navigateur et rendez-vous sur :

  ```text
  http://localhost:8080/kolotv
  ```

- Identifiants par défaut :
  - Username : `admin`
  - Password : `test`

- Si vous accédez à la page d'accueil après authentification, le projet fonctionne correctement.

10) Rebuild rapide lors de modifications du code
- Quand vous modifiez uniquement le code source de l'application (sans toucher à la base de données), il n'est pas nécessaire de reconstruire l'image Oracle.
- Utilisez le script [rebuild.sh](rebuild.sh) pour reconstruire et redémarrer uniquement le conteneur applicatif :

  ```bash
  ./rebuild.sh
  ```

Fichiers de référence
- Script d'import : [import.sh](import.sh)
- Script de rebuild (application) : [rebuild.sh](rebuild.sh)
- Script SQL de debug : [debug.sql](debug.sql)

Remarques et bonnes pratiques
- Conservez le `.dmp` et les fichiers volumineux en dehors du dépôt (disque local ou partage).
- Si vous rencontrez des problèmes, joignez les logs obtenus via `docker compose logs -f` lors de votre demande d'aide.