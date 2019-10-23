#!/usr/bin/env bash
set -ex

docker-compose -f docker-compose.yml up db keycloak redis

bundle install — jobs=3 — retry=3

gem install bundler:2.0.2

bin/rails db:create db:schema:load test BACKTRACE=1


bin/rails submit_coverage
