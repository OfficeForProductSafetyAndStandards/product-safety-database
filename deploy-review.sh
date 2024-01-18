#!/usr/bin/env bash
set -ex

# Name of review app, will be defined outside
if [ -z "$APP_NAME" ]
then
  echo "Please set your application name, eg APP_NAME=ticket-123"
  exit
fi

DOMAIN=london.cloudapps.digital

MANIFEST_FILE=./manifest.review.yml

if [ -z "$DB_NAME" ]
then
  DB_NAME=psd-review-database
fi

# Delete the old app. previously we replaced it but this caused issues with race conditions and re-binding databases when migrations were added
cf delete -f -r $APP_NAME

cf create-service postgres tiny-unencrypted-13 $DB_NAME -c '{"enable_extensions": ["pgcrypto"]}'

# Wait until db is prepared, might take up to 10 minutes
until cf service $DB_NAME > /tmp/db_exists && grep -E "create succeeded|update succeeded" /tmp/db_exists; do sleep 20; echo "Waiting for db"; done

cp -a ${PWD-.}/infrastructure/env/. ${PWD-.}/env/

if [ -z "$WEB_MAX_THREADS" ]
then
  WEB_MAX_THREADS=5
fi

if [ -z "$WORKER_MAX_THREADS" ]
then
  WORKER_MAX_THREADS=10
fi

# Deploy the app
cf push $APP_NAME -f $MANIFEST_FILE --app-start-timeout 180 --var route=$APP_NAME.$DOMAIN --var route-support=$APP_NAME-support.$DOMAIN --var app-name=$APP_NAME --var psd-db-name=$DB_NAME --var psd-host=$APP_NAME.$DOMAIN --var psd-host-support=$APP_NAME-support.$DOMAIN --var psd-host-report=$APP_NAME-report.$DOMAIN --var sidekiq-queue=$APP_NAME --var sentry-current-env=$APP_NAME --var web-max-threads=$WEB_MAX_THREADS --var worker-max-threads=$WORKER_MAX_THREADS

# Remove the copied infrastructure env files to clean up
rm -fR ${PWD-.}/env/
