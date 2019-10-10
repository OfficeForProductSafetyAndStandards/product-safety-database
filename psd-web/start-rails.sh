#!/usr/bin/env bash
set -ex

rails tmp:sockets:clear

bundle exec puma start -c config/puma.rb
