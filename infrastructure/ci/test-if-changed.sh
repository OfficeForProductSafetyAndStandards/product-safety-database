#!/usr/bin/env bash
set -ex

gem install bundler:2.0.2

docker-compose -f docker-compose.yml up --build -d db keycloak

cd psd-web

cp -r ../shared-web  vendor/
ls -la vendor/
bundle install --jobs=3  --retry=3 --deployment

bin/rails db:create db:schema:load test BACKTRACE=1


bin/rails submit_coverage
