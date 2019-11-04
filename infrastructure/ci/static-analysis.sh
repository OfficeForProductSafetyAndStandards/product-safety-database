#!/usr/bin/env bash
set -ex

echo "Running static analysis"
docker-compose -f docker-compose.yml -f docker-compose.ci.yml pull
docker-compose -f docker-compose.yml -f docker-compose.ci.yml run --rm --no-deps psd-web echo 'Gems pre-installed'
docker-compose -f docker-compose.yml -f docker-compose.ci.yml up -d psd-web
docker-compose -f docker-compose.yml -f docker-compose.ci.yml exec psd-web bin/rubocop
docker-compose -f docker-compose.yml -f docker-compose.ci.yml exec psd-web bin/slim-lint app
docker-compose -f docker-compose.yml -f docker-compose.ci.yml exec psd-web yarn eslint app config
docker-compose -f docker-compose.yml -f docker-compose.ci.yml exec psd-web yarn sass-lint 'app/**/*.scss'
docker-compose -f docker-compose.yml -f docker-compose.ci.yml exec psd-web bin/brakeman --no-pager
docker-compose -f docker-compose.yml -f docker-compose.ci.yml down
