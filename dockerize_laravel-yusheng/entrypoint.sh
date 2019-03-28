#!/bin/sh
docker-compose exec -T php chmod -R 777 storage;
docker-compose exec -T php chmod -R 777 public;
docker-compose exec -T php composer install -q;
docker-compose exec -T php php artisan view:clear;
docker-compose exec -T php php artisan route:clear;
docker-compose exec -T php php artisan config:clear;
docker-compose exec -T php php artisan config:cache;
docker-compose exec -T php php artisan optimize;
docker-compose exec -T php chmod -R 777 storage;
docker-compose exec -T php chmod -R 777 public;
docker-compose exec -T php php artisan storage:link;
