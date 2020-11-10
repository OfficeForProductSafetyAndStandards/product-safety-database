#!/usr/bin/env bash
set -ex

gem install bundler:2.0.2

# Ensure all gems are installed.
bundle check || bundle install

# Ensure all node packages are installed.
yarn install


bin/webpack-dev-server --progress &

# Run the passed in command
exec "$@"
