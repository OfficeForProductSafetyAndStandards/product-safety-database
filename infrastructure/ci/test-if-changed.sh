#!/usr/bin/env bash
set -ex

ls -la

cp -r shared-web  psd-web/vendor/

gem install bundler:2.0.2

docker-compose -f docker-compose.yml up --build -d db keycloak


bundle install --jobs=3  --retry=3 --deployment --path ~/bundle-cache

bin/rails db:create db:schema:load test BACKTRACE=1


bin/rails submit_coverage
