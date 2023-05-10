#!/usr/bin/env bash
set -xeuo pipefail
./docker/wait-for-tcp.sh db 5432
./docker/wait-for-tcp.sh redis 6379
./docker/wait-for-tcp.sh antivirus 3006

if [[ -f ./tmp/pids/server.pid ]]; then
  rm ./tmp/pids/server.pid
fi
bundle

if ! [[ -f ./tmp/db-created ]]; then
  bin/rails db:create
  touch ./tmp/db-created
fi

bin/rails db:migrate

if ! [[ -f ./tmp/db-seeded ]]; then
  bin/rails db:seed
  touch ./tmp/db-seeded
fi

bundle exec foreman start -f Procfile.docker.dev
