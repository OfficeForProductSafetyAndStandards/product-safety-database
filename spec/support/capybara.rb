require "capybara/rspec"
require "capybara-screenshot/rspec"
require "capybara/mechanize"

# Increase redirect limit (default is 5) due to wizard controller redirects
Capybara.register_driver :rack_test do |app|
  Capybara::RackTest::Driver.new(app, respect_data_method: true, redirect_limit: 6)
end

Capybara.register_driver :mechanize do |_app|
  Capybara::Mechanize::Driver.new(proc {})
end
