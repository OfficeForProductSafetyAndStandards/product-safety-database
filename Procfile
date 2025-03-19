web: cp -r /workspace/db-copy/* /workspace/db/ && cp -r /workspace/public-copy/* /workspace/public/ && bundle exec rails assets:precompile && bin/rails server
jobs: bin/sidekiq -C config/sidekiq.yml
js: yarn build --watch
css: yarn build:css --watch
