#!/usr/bin/env bash
# Builds Docker images for components that have changes, and then pushes all current images
# tagged with the build ID to DockerHub.
set -ex

COMPONENTS=(
    'psd-web'
    'psd-worker'
)

function docker_tag_exists {
    curl --silent -f -lSL https://index.docker.io/v1/repositories/$1/tags/$2 > /dev/null
}

echo "Logging into DockerHub"
docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD

CHANGED_COMPONENTS="$(./infrastructure/ci/get-changed-components.sh)"

for COMPONENT in "${COMPONENTS[@]}"; do
    if [[ $CHANGED_COMPONENTS =~ ((^| )$COMPONENT($| )) ]]; then
        echo "Building component $COMPONENT"
        DOCKER_ORG=$DOCKER_ORG docker-compose -f docker-compose.yml -f docker-compose.ci.yml build $COMPONENT
    elif docker_tag_exists $DOCKER_ORG/$COMPONENT $BRANCH; then
        echo "No changes for component $COMPONENT, pulling $BRANCH image"
        docker pull $DOCKER_ORG/$COMPONENT:$BRANCH
        docker tag $DOCKER_ORG/$COMPONENT:$BRANCH $DOCKER_ORG/$COMPONENT:$BUILD_ID
    else
        echo "No changes for component $COMPONENT, but $BRANCH image does not exist in repo"
        echo "Building component $COMPONENT"
        DOCKER_ORG=$DOCKER_ORG docker-compose -f docker-compose.yml -f docker-compose.ci.yml build $COMPONENT
    fi

    echo "Pushing image for component $COMPONENT with tag $BUILD_ID"
    docker push $DOCKER_ORG/$COMPONENT:$BUILD_ID
done
