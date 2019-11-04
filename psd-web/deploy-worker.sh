#!/usr/bin/env bash
set -ex

# This is the CI server script to deploy the sidekiq worker
#
# The working directory should be the git root
#
# The caller should have the following environment variables set:
#
# SPACE: the space to which you want to deploy

APP_PREEXISTS=$(cf app psd-worker && echo 0 || echo 1)

if [[ ! $APP_PREEXISTS ]]; then
    echo "No existing app found. Performing first-time setup."
fi

# Copy the environment helper script
cp -a ./infrastructure/env/. ./psd-web/env/

# Circumvent the cloudfoundry asset compilation step - https://github.com/cloudfoundry/ruby-buildpack/blob/master/src/ruby/finalize/finalize.go#L213
mkdir -p ./psd-web/public/assets
touch ./psd-web/public/assets/.sprockets-manifest-qq.json

cf push -f ./psd-worker/manifest.yml psd-worker $( [[ ! ${APP_PREEXISTS} ]] && printf %s '--no-start' )
