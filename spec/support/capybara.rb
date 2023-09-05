require "capybara/rspec"
require "capybara-screenshot/rspec"

# Increase redirect limit (default is 5) due to wizard controller redirects
Capybara.register_driver :rack_test do |app|
  Capybara::RackTest::Driver.new(app, respect_data_method: true, redirect_limit: 6)
end

Capybara.test_id = "data-test"
