#!/bin/bash
# Arrêter et supprimer seulement l'application
docker compose stop kolotv-wildfly
docker rm kolotv-wildfly 2>/dev/null || true

# Nettoyer les images et caches
# docker image prune -f
docker builder prune -f

# Rebuilder
docker compose build --no-cache kolotv-app

# Redémarrer
docker compose up -d kolotv-app