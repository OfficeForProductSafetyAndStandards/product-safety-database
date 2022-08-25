source "https://rubygems.org"

ruby "~> 3.0"

gem "kaminari", "~> 1.2" # Must be loaded before elasticsearch gems

gem "activerecord-pg_enum", "~> 2.0"
gem "aws-sdk-s3", "~> 1.114"
gem "aws-sdk-s3control", "~> 1.50"
gem "caxlsx"
gem "caxlsx_rails"
gem "cf-app-utils", "~> 0.6"
gem "devise", "~> 4.8"
gem "devise-encryptable", "~> 0.2"
gem "draper", "~> 4.0"
gem "elasticsearch"
gem "elasticsearch-model"
gem "elasticsearch-rails"
gem "govuk_notify_rails", "~> 2.2"
gem "image_processing"
gem "interactor", "~> 3.1"
gem "jbuilder", "~> 2.11"
gem "lograge", "~> 0.12"
gem "mini_magick", "~> 4.11"

# ActionMailer dependencies
gem "net-imap"
gem "net-pop"
gem "net-smtp"

gem "pg", "~> 1.4"
gem "pghero", "~> 2.8"
gem "puma", "~> 5.6"
gem "pundit", "~> 2.1"
gem "rack", "~> 2.2.4"
gem "rails", "~> 6.1.6"
gem "redcarpet", "~> 3.5"
gem "redis-rails", "~> 5.0"
gem "rest-client", "~> 2.1"
gem "sass-rails", "~> 6.0"
gem "scout_apm", "~> 5.3"
gem "sentry-rails"
gem "sentry-sidekiq"
gem "sidekiq", "~> 6.5"
gem "sidekiq-scheduler", "~> 4.0.2"
gem "sprockets", "~> 4.1.1"
gem "sprockets-rails", require: "sprockets/railtie"
gem "strong_migrations", "~> 1.2"
gem "tty-table", require: false
gem "validate_email", "~> 0.1"
gem "webpacker", "~> 5.4"
gem "wicked", "~> 1.4"

gem "govuk-design-system-rails", git: "https://github.com/UKGovernmentBEIS/govuk-design-system-rails", tag: "0.9.1", require: "govuk_design_system"

gem "bootsnap"

group :development, :test do
  gem "awesome_print", "~> 1.9", require: "ap"
  gem "byebug", "~> 11.1"
  gem "dotenv-rails", "~> 2.8"
  gem "parallel_tests", "~> 3.11.1"
  gem "pry", "~> 0.13"
  gem "pry-byebug", "~> 3.10"
  gem "pry-doc", "~> 1.3"
end

group :development do
  gem "listen", "~> 3.7"
  gem "m", "~> 1.6"
  gem "rails-erd"
  gem "solargraph", "~> 0.44"
  gem "spring", "~> 4.0"
  gem "spring-commands-rspec", "~> 1.0"
end

group :test do
  gem "capybara", "~> 3.36"
  gem "capybara-screenshot", "~> 1.0"
  gem "database_cleaner", "~> 2.0"
  gem "factory_bot_rails", "~> 6.2"
  gem "faker", "~> 2.22"
  gem "launchy", "~> 2.5"
  gem "rails-controller-testing", "~> 1.0"
  gem "roo", "~> 2.9"
  gem "rspec"
  gem "rspec-mocks", "~> 3.11"
  gem "rspec-rails"
  gem "rubocop", "~> 1.35"
  gem "rubocop-govuk", "~> 4.7"
  gem "rubocop-performance", "~> 1.14"
  gem "rubocop-rspec", "~> 2.12", require: false
  gem "scss_lint-govuk", "~> 0.2"
  gem "selenium-webdriver", "~> 4.4"
  gem "shoulda-matchers"
  gem "simplecov"
  gem "simplecov-console", "~> 0.9"
  gem "simplecov-lcov"
  gem "super_diff"
  gem "webmock", "~> 3.18"
end
