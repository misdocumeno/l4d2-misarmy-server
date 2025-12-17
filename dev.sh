#!/bin/bash

set -e

gomplate \
    -f docker-compose.yml.tmpl \
    -c .="config/dev.yml" \
    > docker-compose.yml

if [ "$SM_ENV" = "debug" ]; then
  # we need the sourcemaps in local too
  npm run build

  docker compose run \
      --rm --build --service-ports --remove-orphans \
      --name srcds-dev \
      -e SM_ENV=$SM_ENV \
      srcds-dev
else
  docker compose run \
      --rm --build --service-ports --remove-orphans \
      --name srcds-dev \
      srcds-dev
fi