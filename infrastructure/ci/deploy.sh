#!/usr/bin/env bash
set -ex

# The caller should have the following environment variables set:
#
# CF_USERNAME: cloudfoundry username
# CF_PASSWORD: cloudfoundry password
# SPACE: the space to which you want to deploy

./infrastructure/ci/install-cf.sh

cf login -a api.london.cloud.service.gov.uk -u $CF_USERNAME -p $CF_PASSWORD -o 'beis-opss' -s $SPACE

if [[ $COMPONENT == "psd-web" ]]; then
  ./psd-web/deploy.sh
else
  ./psd-web/deploy-worker.sh
fi

cf logout

docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
docker pull $DOCKER_ORG/$COMPONENT:$BUILD_ID
docker tag $DOCKER_ORG/$COMPONENT:$BUILD_ID $DOCKER_ORG/$COMPONENT:$BRANCH
docker push $DOCKER_ORG/$COMPONENT:$BRANCH
