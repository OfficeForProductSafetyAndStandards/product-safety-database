require "simplecov"
require "simplecov-lcov"

if ENV["CI"]
  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.single_report_path = "coverage/lcov.info"
  end
  SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
end

unless ENV["COVERAGE"] == "false"
  require "coveralls"
  Coveralls.wear!("rails")
  SimpleCov.start do
    enable_coverage :branch
    add_filter %r{^/config/}
    add_filter %r{^/spec/}
  end
end

# Optional: Add an HTML formatter explicitly
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::LcovFormatter
])

require "spec_helper"
require "domain_helpers"
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)

abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "super_diff/rspec-rails"

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("test/fixtures")]
  config.include Rails.application.routes.url_helpers
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include ActiveSupport::Testing::TimeHelpers
  config.include ActiveSupport::Testing::Assertions

  config.include PageExpectations, type: :feature
  config.include EmailExpectations, type: :feature

  config.include DomainHelpers

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!
end
