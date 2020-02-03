ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)

if ENV["CI"]
  # It's important that simplecov is "require"d early in the file
  require "simplecov"
  require "simplecov-console"
  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ]
  SimpleCov.start
end
require "rails/test_help"
require "rspec/mocks/standalone"

# Added Webmock only to allow use of stub_request - Minitest suite is deprecated
require "webmock/minitest"
WebMock.allow_net_connect!

class ActiveSupport::TestCase
  include ::RSpec::Mocks::ExampleMethods

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Import all relevant models into Elasticsearch
  def self.import_into_elasticsearch
    unless @models_imported
      ActiveRecord::Base.descendants.each do |model|
        if model.respond_to?(:__elasticsearch__) && !model.superclass.respond_to?(:__elasticsearch__)
          model.import force: true, refresh: true
        end
      end
      @models_imported = true
    end
  end

  def setup
    self.class.import_into_elasticsearch
  end

  def teardown
    WebMock.reset!
  end

  # TODO: these roles will soon get moved to the database, allowing this to be removed.
  def mock_keycloak_user_roles(roles)
    allow(KeycloakClient.instance).to receive(:get_user_roles) { roles }
  end

  # TODO: this URL will soon move to within the app, allowing this to be removed.
  def mock_keycloak_account_url
    allow(KeycloakClient.instance).to receive(:user_account_url) { "http://test.com/account" }
  end

  def stub_antivirus_api
    antivirus_url = Rails.application.config.antivirus_url
    stubbed_response = JSON.generate(safe: true)
    stub_request(:any, /#{Regexp.quote(antivirus_url)}/).to_return(body: stubbed_response, status: 200)
  end

  def reset_keycloak_and_notify_mocks
    allow(KeycloakClient.instance).to receive(:get_user_roles).and_call_original
  end

  def stub_notify_mailer
    result = ""
    allow(result).to receive(:deliver_later)
    allow(NotifyMailer).to receive(:alert) { result }
    allow(NotifyMailer).to receive(:investigation_updated) { result }
    allow(NotifyMailer).to receive(:investigation_created) { result }
    allow(NotifyMailer).to receive(:user_added_to_team) { result }
  end

  def assert_same_elements(expected, actual, msg = nil)
    full_message = message(msg, "") { diff(expected, actual) }
    condition = (expected.size == actual.size) && (expected - actual == [])
    assert(condition, full_message)
  end

  def create_new_case
    description = "new_investigation_description"
    Investigation::Allegation.create(description: description)
  end

  def load_case(key)
    Investigation.import force: true, refresh: true
    investigation = investigations(key)
    investigation.assignee = User.current
    investigation.save
    investigation
  end
end

ActionDispatch::IntegrationTest.include Devise::Test::IntegrationHelpers
