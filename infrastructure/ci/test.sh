#!/usr/bin/env bash
set -ex

docker-compose -f docker-compose.yml -f docker-compose.ci.yml pull
docker-compose -f docker-compose.yml -f docker-compose.ci.yml run --rm --no-deps psd-web echo 'Gems pre-installed'
docker-compose -f docker-compose.yml -f docker-compose.ci.yml up -d psd-web

echo "Running tests"
docker-compose -f docker-compose.yml -f docker-compose.ci.yml run --rm start_dependencies
docker-compose -f docker-compose.yml -f docker-compose.ci.yml exec psd-web bin/rake yarn:install db:create db:schema:load test:all

docker-compose -f docker-compose.yml -f docker-compose.ci.yml exec psd-web bin/rake submit_coverage
docker-compose -f docker-compose.yml -f docker-compose.ci.yml down
