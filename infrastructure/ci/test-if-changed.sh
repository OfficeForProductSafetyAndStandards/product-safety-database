#!/usr/bin/env bash
set -ex

export DATABASE_URL=postgres://postgres@localhost:5432/psd_test
export KEYCLOAK_AUTH_URL=http://localhost:8080/auth
export ELASTICSEARCH_URL=http://localhost:9200

ps aux
sudo ls -la /etc/elasticsearch

sudo ln -s /etc/elasticsearch /usr/share/elasticsearch/config

sudo chown -R elasticsearch:elasticsearch /var/lib/elasticsearch
sudo chown -R elasticsearch:elasticsearch /var/run/elasticsearch
sudo chown -R elasticsearch:elasticsearch /etc/elasticsearch


docker-compose -f docker-compose.yml up --build -d db keycloak

gem install bundler:2.0.2

cd psd-web

mkdir -p  vendor/shared-web

cp -R ../shared-web  vendor/shared-web

bundle install --jobs=3  --retry=3

bin/rails db:create db:schema:load test BACKTRACE=1

bin/rails submit_coverage
