#!/usr/bin/env bash
set -ex

# Set the manifest file
MANIFEST_FILE=./psd-web/manifest.yml

# Copy the environment helper script
cp -a ./infrastructure/env/. ./psd-web/env/

# Set the amount of time in minutes that the CLI will wait for all instances to start.
# Because of the rolling deployment strategy, this should be set to at least the amount of
# time each app takes to start multiplied by the number of instances.
#
# See https://docs.cloudfoundry.org/devguide/deploy-apps/large-app-deploy.html
export CF_STARTUP_TIMEOUT=15

# Deploy the app
cf7 push $APP_NAME -f $MANIFEST_FILE --app-start-timeout 180 --var app-name=$APP_NAME --var psd-host=$DOMAIN --var web-memory=$WEB_MEMORY --var worker-memory=$WORKER_MEMORY --var web-instances=$WEB_INSTANCES --var worker-instances=$WORKER_INSTANCES --var web-max-threads=$WEB_MAX_THREADS --var worker-max-threads=$WORKER_MAX_THREADS --strategy rolling

# Remove the copied infrastructure env files to clean up
rm -R psd-web/env/
