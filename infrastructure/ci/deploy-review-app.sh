#!/usr/bin/env bash
set -ex

# The caller should have the following environment variables set:
#
# CF_USERNAME: cloudfoundry username
# CF_PASSWORD: cloudfoundry password
# SPACE: the space to which you want to deploy

./infrastructure/ci/install-cf.sh
cf login -a api.london.cloud.service.gov.uk -u $CF_USERNAME -p $CF_PASSWORD -o 'beis-opss' -s $SPACE
export DB_VERSION=`cat psd-web/db/schema.rb | grep 'ActiveRecord::Schema.define' | grep -o '[0-9_]\+'`
export REVIEW_INSTANCE_NAME=pr-$TRAVIS_PULL_REQUEST
export DB_NAME=cosmetics-db-$DB_VERSION
./$COMPONENT/deploy-review.sh
cf logout
