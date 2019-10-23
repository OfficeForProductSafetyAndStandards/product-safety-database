#!/usr/bin/env bash
set -ex


cd $HOME

wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.4.1-linux-x86_64.tar.gz
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.4.1-linux-x86_64.tar.gz.sha512
shasum -a 512 -c elasticsearch-7.4.1-linux-x86_64.tar.gz.sha512
tar -xzf elasticsearch-7.4.1-linux-x86_64.tar.gz
ls -la  elasticsearch-7.4.1/

export ES_HOME=$HOME/elasticsearch-7.4.1/
export DATABASE_URL=postgres://postgres@localhost:5432/psd_test
export KEYCLOAK_AUTH_URL=http://localhost:8080/auth
export ELASTICSEARCH_URL=http://localhost:9250

cd $HOME/build/UKGovernmentBEIS/beis-opss-psd

docker-compose -f docker-compose.yml up --build -d db keycloak

cd $HOME/build/UKGovernmentBEIS/beis-opss-psd/psd-web

mkdir -p  vendor/shared-web

cp -R ../shared-web  vendor/shared-web

gem install bundler:2.0.2

bundle install --jobs=3  --retry=3

bin/rails db:create db:schema:load test BACKTRACE=1

bin/rails submit_coverage
