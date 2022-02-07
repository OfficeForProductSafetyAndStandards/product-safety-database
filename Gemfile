source "https://rubygems.org"

ruby "~> 3.0"

gem "kaminari", "~> 1.2" # Must be loaded before elasticsearch gems

gem "aws-sdk-s3", "~> 1.112"
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
gem "jbuilder"
gem "lograge", "~> 0.11"
gem "mini_magick", "~> 4.11"
gem "pg", "~> 1.3"
gem "pghero", "~> 2.8"
gem "puma", "~> 5.6"
gem "pundit", "~> 2.1"
gem "rack", "~> 2.2"
gem "rails", "~> 7.0.1"
gem "redcarpet", "~> 3.5"
gem "redis-rails", "~> 5.0"
gem "rest-client", "~> 2.1"
gem "sassc-rails"
gem "scout_apm", "~> 5.1"
gem "sentry-rails"
gem "sentry-sidekiq"
gem "sidekiq", "~> 6.4"
gem "sidekiq-cron", "~> 1.2"
gem "slim-rails"
gem "stimulus-rails"
# gem "sprockets", "4.0.2" # Unable to upgrade until https://github.com/rails/sprockets/issues/633 is resolved
gem "bootsnap", require: false
gem "sprockets-rails"
gem "strong_migrations", "~> 0.7"
gem "tty-table", require: false
gem "validate_email", "~> 0.1"
gem "webpacker", "~> 5.4"
gem "wicked", "~> 1.4"

gem "govuk-design-system-rails", git: "https://github.com/UKGovernmentBEIS/govuk-design-system-rails", tag: "0.8.1", require: "govuk_design_system"

group :development, :test do
  gem "awesome_print", "~> 1.9", require: "ap"
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "dotenv-rails", "~> 2.7"
  gem "parallel_tests"
  gem "pry", "~> 0.13"
  gem "pry-byebug", "~> 3.9"
  gem "pry-doc", "~> 1.3"
end

group :development do
  gem "m", "~> 1.6"
  gem "solargraph", "~> 0.44"
  gem "web-console"
end

group :test do
  gem "capybara", "~> 3.36"
  gem "capybara-screenshot", "~> 1.0"
  gem "database_cleaner", "~> 2.0"
  gem "factory_bot_rails", "~> 6.2"
  gem "faker", "~> 2.19"
  gem "launchy", "~> 2.5"
  gem "rails-controller-testing", "~> 1.0"
  gem "roo", "~> 2.8"
  gem "rspec"
  gem "rspec-mocks"
  gem "rspec-rails"
  gem "rubocop", "~> 1.25"
  gem "rubocop-govuk", "~> 4.3"
  gem "rubocop-performance", "~> 1.13"
  gem "rubocop-rspec", require: false
  gem "scss_lint-govuk", "~> 0.2"
  gem "selenium-webdriver", "~> 4.1"
  gem "shoulda-matchers"
  gem "simplecov"
  gem "simplecov-console", "~> 0.9"
  gem "simplecov-lcov"
  gem "super_diff"
  gem "webdrivers"
  gem "webmock", "~> 3.14"
end
