#!/usr/bin/env bash
set -ex

# Name of review app, will be defined outside
if [ -z "$APP_NAME" ]
then
  echo "Please set your application name, eg APP_NAME=ticket-123"
  exit
fi

DOMAIN=london.cloudapps.digital

MANIFEST_FILE=./psd-web/manifest.review.yml

if [ -z "$DB_NAME" ]
then
  DB_NAME=psd-review-database
fi
cf7 create-service postgres small-10 $DB_NAME

# Wait until db is prepared, might take up to 10 minutes
until cf7 service $DB_NAME > /tmp/db_exists && grep -E "create succeeded|update succeeded" /tmp/db_exists; do sleep 20; echo "Waiting for db"; done

cp -a ${PWD-.}/infrastructure/env/. ${PWD-.}/psd-web/env/

# Set the amount of time in minutes that the CLI will wait for all instances to start.
# Because of the rolling deployment strategy, this should be set to at least the amount of
# time each app takes to start multiplied by the number of instances.
#
# See https://docs.cloudfoundry.org/devguide/deploy-apps/large-app-deploy.html
export CF_STARTUP_TIMEOUT=10

# Deploy the app
cf7 push $APP_NAME -f $MANIFEST_FILE --app-start-timeout 180 --var route=$APP_NAME.$DOMAIN --var app-name=$APP_NAME --var psd-db-name=$DB_NAME --var psd-host=$APP_NAME.$DOMAIN --var sidekiq-queue=$APP_NAME --var sentry-current-env=$APP_NAME --strategy rolling


# Remove the copied infrastructure env files to clean up
rm -fR ${PWD-.}/psd-web/env/
