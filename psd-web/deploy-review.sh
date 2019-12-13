#!/usr/bin/env bash
set -ex

# Name of review app, will be defined outside
if [ -z "$REVIEW_INSTANCE_NAME" ]
then
  echo "Please set your application name, eg REVIEW_INSTANCE_NAME=ticket-123"
  exit
fi

INSTANCE_NAME=psd-$REVIEW_INSTANCE_NAME
WEB=$INSTANCE_NAME-web
WORKER=$INSTANCE_NAME-worker
DOMAIN=london.cloudapps.digital

MANIFEST_FILE=${PWD-.}/psd-web/manifest.review.yml

if [ -z "$DB_NAME" ]
then
  DB_NAME=psd-review-database
fi
cf7 create-service postgres small-10 $DB_NAME

# Wait until db is prepared, might take up to 10 minutes
until cf7 service $DB_NAME > /tmp/db_exists && grep "create succeeded" /tmp/db_exists; do sleep 20; echo "Waiting for db"; done

cp -a ${PWD-.}/infrastructure/env/. ${PWD-.}/psd-web/env/

# Deploy the web app
cf7 push -f $MANIFEST_FILE $WEB --var route=$WEB.$DOMAIN --var psd-instance-name=$REVIEW_INSTANCE_NAME --var psd-db-name=$DB_NAME --var psd-host=$WEB.$DOMAIN --var sidekiq-queue=$INSTANCE_NAME --var sentry-current-env=$REVIEW_INSTANCE_NAME --strategy rolling

# Deploy the worker app
cf7 push -f $MANIFEST_FILE $WORKER --var route=$WORKER.$DOMAIN --var psd-instance-name=$REVIEW_INSTANCE_NAME --var psd-db-name=$DB_NAME --var psd-host=$WEB.$DOMAIN --var sidekiq-queue=$INSTANCE_NAME --var sentry-current-env=$REVIEW_INSTANCE_NAME --strategy rolling

# Remove the copied infrastructure env files to clean up
rm -fR ${PWD-.}/psd-web/env/
