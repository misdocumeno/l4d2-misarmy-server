#!/bin/bash

gomplate \
    -f docker-compose.yml.tmpl \
    -c .="config/dev.yml" \
    > docker-compose.yml

docker compose run \
    --rm --build --service-ports --remove-orphans \
    --name srcds-dev \
    srcds-dev