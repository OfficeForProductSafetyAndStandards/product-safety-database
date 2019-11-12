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
cf create-service postgres small-10 $DB_NAME

# Wait until db is prepared, might take up to 10 minutes
until cf service $DB_NAME > /tmp/db_exists && grep "create succeeded" /tmp/db_exists; do sleep 20; echo "Waiting for db"; done

cp -a ${PWD-.}/infrastructure/env/. ${PWD-.}/psd-web/env/

# Deploy the app and set the hostname
cf push -f $MANIFEST_FILE $WEB -d $DOMAIN --hostname $WEB --no-start --var psd-instance-name=$REVIEW_INSTANCE_NAME --var psd-db-name=$DB_NAME
cf push -f $MANIFEST_FILE $WORKER -d $DOMAIN --no-start --var psd-instance-name=$REVIEW_INSTANCE_NAME --var psd-db-name=$DB_NAME

cf set-env $WEB PSD_HOST "$WEB.$DOMAIN"

cf set-env $WEB SIDEKIQ_QUEUE "$INSTANCE_NAME"
cf set-env $WORKER SIDEKIQ_QUEUE "$INSTANCE_NAME"

rm -fR ${PWD-.}/psd-web/env/

cf start $WEB
cf start $WORKER
