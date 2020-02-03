require "capybara/rspec"
require "capybara-screenshot/rspec"
Capybara.default_host = "http://#{ENV['HTTP_HOST']}:#{ENV['HTTP_PORT']}"
