#!/usr/bin/env bash
set -ex


cd $HOME

wget --quiet https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.8.4.tar.gz
tar -xzf elasticsearch-6.8.4.tar.gz
ls -la  elasticsearch-6.8.4/

export ES_HOME=$HOME/elasticsearch-6.8.4/
export DATABASE_URL=postgres://postgres@localhost:5432/psd_test
export KEYCLOAK_AUTH_URL=http://localhost:8080/auth
export ELASTICSEARCH_URL=http://localhost:9250
export REDIS_URL=redis://localhost:6379/0

cd $HOME/build/UKGovernmentBEIS/beis-opss-psd

docker-compose -f docker-compose.yml up --build -d db keycloak

cd $HOME/build/UKGovernmentBEIS/beis-opss-psd/psd-web

mkdir -p  vendor/shared-web

cp -R ../shared-web  vendor/shared-web

bin/rails db:create db:schema:load test BACKTRACE=1

bin/rails submit_coverage
