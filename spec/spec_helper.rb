ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
require "rspec/rails"

require "webmock/rspec"
require "simplecov"

# Output coverage in LCOV format for CodeCov in CI environment
if ENV["CI"]
  require "simplecov-lcov"
  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.single_report_path = "coverage/lcov.info"
  end
  SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter

end
unless ENV["COVERAGE"] == "false"
  SimpleCov.start "rails" do
    enable_coverage :branch
  end
end

require "domain_helpers"
require "sidekiq/testing"
require "super_diff/rspec-rails"

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  # config.fixture_path = Rails.root.join("test/fixtures")
  config.include Rails.application.routes.url_helpers

  config.include ActiveSupport::Testing::TimeHelpers
  config.include ActiveSupport::Testing::Assertions

  config.include PageExpectations, type: :feature
  config.include EmailExpectations, type: :feature

  config.include DomainHelpers

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before(:suite) do
    uri = URI(ENV.fetch("OPENSEARCH_URL"))
    WebMock.disable_net_connect!(allow: "#{uri.host}:#{uri.port}")
    Investigation.reindex

    Searchkick.disable_callbacks
  end

  config.around(:each, with_opensearch: true) do |example|
    Searchkick.callbacks(nil) do
      example.run
    end
  end

  config.disable_monkey_patching!

  config.example_status_persistence_file_path = "examples.txt"

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_when_matching :focus

  config.default_formatter = "doc" if config.files_to_run.one?

  config.order = :random

  Kernel.srand config.seed
end
