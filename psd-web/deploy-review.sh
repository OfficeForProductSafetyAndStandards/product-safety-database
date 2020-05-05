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

# Unbind any databases which may already be bound to this app (if it already exists) and which are no longer required
for existing_db_name in `cf7 services | grep $APP_NAME | grep postgres | awk '{print $1}'`; do
  if [ $existing_db_name != $DB_NAME ]
  then
    cf7 unbind-service $APP_NAME $existing_db_name
  fi
done

cf7 create-service postgres small-10 $DB_NAME -c '{"enable_extensions": ["pgcrypto"]}'

# Wait until db is prepared, might take up to 10 minutes
until cf7 service $DB_NAME > /tmp/db_exists && grep -E "create succeeded|update succeeded" /tmp/db_exists; do sleep 20; echo "Waiting for db"; done

cp -a ${PWD-.}/infrastructure/env/. ${PWD-.}/psd-web/env/

if [ -z "$WEB_MAX_THREADS" ]
then
  WEB_MAX_THREADS=5
fi

if [ -z "$WORKER_MAX_THREADS" ]
then
  WORKER_MAX_THREADS=10
fi

# Set the amount of time in minutes that the CLI will wait for all instances to start.
# Because of the rolling deployment strategy, this should be set to at least the amount of
# time each app takes to start multiplied by the number of instances.
#
# See https://docs.cloudfoundry.org/devguide/deploy-apps/large-app-deploy.html
export CF_STARTUP_TIMEOUT=10


# Cancel any existing deployments in progress
if cf7 cancel-deployment $APP_NAME
then
  # Wait enough time for cancellation to finish
  sleep 6
fi

# Deploy the app
cf7 push $APP_NAME -f $MANIFEST_FILE --app-start-timeout 180 --var route=$APP_NAME.$DOMAIN --var app-name=$APP_NAME --var psd-db-name=$DB_NAME --var psd-host=$APP_NAME.$DOMAIN --var sidekiq-queue=$APP_NAME --var sentry-current-env=$APP_NAME --var web-max-threads=$WEB_MAX_THREADS --var worker-max-threads=$WORKER_MAX_THREADS --strategy rolling

# run the seeds once the app has migrated, startd and
# the psd-seeds service was successfully bound to the app
cf7 run-task "export \$(./env/get-env-from-vcap.sh) && bin/rails db:seed"

# Remove the copied infrastructure env files to clean up
rm -fR ${PWD-.}/psd-web/env/
