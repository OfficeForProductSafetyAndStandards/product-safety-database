#!/usr/bin/env bash
# Builds Docker images for components that have changes, and then pushes all current images
# tagged with the build ID to DockerHub.
set -ex

echo "Logging into DockerHub"
docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD

COMPONENTS=(
    'psd-web'
    'psd-worker'
)

for COMPONENT in "${COMPONENTS[@]}"; do
    echo "Building component $COMPONENT"
    DOCKER_ORG=$DOCKER_ORG docker-compose -f docker-compose.yml -f docker-compose.ci.yml build $COMPONENT

    echo "Pushing image for component $COMPONENT with tag $BUILD_ID"
    docker push $DOCKER_ORG/$COMPONENT:$BUILD_ID
done
