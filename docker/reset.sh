#!/usr/bin/env bash
set -xeuo pipefail

echo
read -p "This will reset the database - all data will be lost? y/n" -n 1 -r
echo
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  docker-compose run web rm /rails/tmp/db-created
  docker-compose run web rm /rails/tmp/db-seeded
  docker-compose run web bundle exec rake db:drop

  echo "Database reset"
else
  echo "Aborting"
fi
