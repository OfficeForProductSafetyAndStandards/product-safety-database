#!/usr/bin/env bash
set -ex

# Name of review app, will be defined outside
if [ -z "$REVIEW_INSTANCE_NAME" ]
then
  echo "Please set your application name, eg REVIEW_INSTANCE_NAME=ticket-123"
  exit
fi

HOSTNAME=psd-$REVIEW_INSTANCE_NAME-web
DOMAIN=london.cloudapps.digital
APP=$HOSTNAME

# Please note new manifest file
MANIFEST_FILE=./psd-web/manifest.review.yml

if [ -z "$DB_NAME" ]
then
  DB_NAME=psd-review-database
fi
cf create-service postgres small-10 $DB_NAME

# Wait until db is prepared, might take up to 10 minutes
until cf service $DB_NAME > /tmp/db_exists && grep "create succeeded" /tmp/db_exists; do sleep 20; echo "Waiting for db"; done
cp -a ./infrastructure/env/. ./psd-web/env/

# Deploy the app and set the hostname
cf push $APP -f $MANIFEST_FILE -d $DOMAIN --hostname $HOSTNAME --no-start --var psd-instance-name=$REVIEW_INSTANCE_NAME --var psd-db-name=$DB_NAME

cf set-env $APP PSD_HOST "$HOSTNAME.$DOMAIN"

cf start $APP
