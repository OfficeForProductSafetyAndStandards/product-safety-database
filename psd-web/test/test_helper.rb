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

  def initialize *args
    @keycloak_client_instance = KeycloakClient.instance
    super(*args)
  end

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

  # On top of mocking out external services, this method also sets the user to an initial,
  # sensible value, but it should only be run once per test.
  # To change currently logged in user afterwards call `sign_in_as(...)`
  def mock_out_keycloak_and_notify(name: "User_one")
    @users = [test_user(name: "User_four"),
              test_user(name: "User_one"),
              test_user(name: "User_two"),
              test_user(name: "User_three"),
              test_user(name: "Ts_user", ts_user: true),
              non_psd_user(name: "Non_psd_user")]
    @organisations = organisations
    @teams = all_teams
    @team_users = []

    allow(Keycloak::Client).to receive(:openid_configuration) { true }

    allow(@keycloak_client_instance).to receive(:all_organisations) { @organisations.deep_dup }
    allow(@keycloak_client_instance).to receive(:all_teams) { @teams.deep_dup }
    allow(@keycloak_client_instance).to receive(:all_users) { @users.deep_dup }
    allow(@keycloak_client_instance).to receive(:get_user_roles) { [:psd_user] }

    stub_user_management
    set_default_group_memberships
    Organisation.load_from_keycloak
    Team.load_from_keycloak
    User.load_from_keycloak
    sign_in_as User.find_by(name: "Test #{name}")
    stub_notify_mailer
  end

  def stub_antivirus_api
    antivirus_url = Rails.application.config.antivirus_url
    stubbed_response = JSON.generate(safe: true)
    stub_request(:any, /#{Regexp.quote(antivirus_url)}/).to_return(body: stubbed_response, status: 200)
  end

  def sign_in_as(user)
    allow(@keycloak_client_instance).to receive(:user_signed_in?).and_return(true)
    allow(@keycloak_client_instance).to receive(:user_info).and_return(user.attributes.symbolize_keys.slice(:id, :email, :name))
    allow(@keycloak_client_instance).to receive(:user_account_url) { "http://test.com/account" }
    User.current = user
    User.current.update!(has_accepted_declaration: true)
  end

  def reset_keycloak_and_notify_mocks
    allow(@keycloak_client_instance).to receive(:get_user_roles).and_call_original
    allow(@keycloak_client_instance).to receive(:user_signed_in?).and_call_original
    allow(@keycloak_client_instance).to receive(:user_info).and_call_original
    allow(@keycloak_client_instance).to receive(:all_users).and_call_original
    allow(@keycloak_client_instance).to receive(:all_organisations).and_call_original
    allow(@keycloak_client_instance).to receive(:all_teams).and_call_original
    restore_user_management

    allow(NotifyMailer).to receive(:alert).and_call_original
    allow(NotifyMailer).to receive(:investigation_updated).and_call_original
    allow(NotifyMailer).to receive(:investigation_created).and_call_original
    allow(NotifyMailer).to receive(:user_added_to_team).and_call_original

    @keycloak_client_instance.reset
  end

  def stub_notify_mailer
    result = ""
    allow(result).to receive(:deliver_later)
    allow(NotifyMailer).to receive(:alert) { result }
    allow(NotifyMailer).to receive(:investigation_updated) { result }
    allow(NotifyMailer).to receive(:investigation_created) { result }
    allow(NotifyMailer).to receive(:user_added_to_team) { result }
  end

  # This is a public method that updates both the passed in user object and the KC mocking
  def mock_user_as_opss(user)
    set_kc_user_as_opss user.id
    user.reload
    User.current&.reload
  end

  # This is a public method that updates both the passed in user object and the KC mocking
  def mock_user_as_non_opss(user)
    set_kc_user_as_non_opss user.id
    user.reload
    User.current&.reload
  end

  def set_user_as_team_admin(user = User.current)
    allow(@keycloak_client_instance).to receive(:get_user_roles).with(user.id) { %i[psd_user team_admin] }
  end

  def set_user_as_not_team_admin(user = User.current)
    allow(@keycloak_client_instance).to receive(:get_user_roles).with(user.id) { [:psd_user] }
  end

  def add_user_to_opss_team(user_id:, team_id:)
    set_kc_user_as_opss user_id
    add_user_to_team user_id, team_id
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

private

  def test_user(name: "User_one", ts_user: false)
    id = SecureRandom.uuid

    roles = [:psd_user]
    roles << :opss_user if ts_user
    allow(@keycloak_client_instance).to receive(:get_user_roles).with(id) { roles }

    { id: id, email: "#{name}@example.com", name: "Test #{name}" }
  end

  def non_psd_user(name:)
    id = SecureRandom.uuid
    allow(@keycloak_client_instance).to receive(:get_user_roles).with(id) { [] }

    { id: id, email: "#{name}@example.com", name: "Test #{name}" }
  end

  def organisations
    [non_opss_organisation, opss_organisation]
  end

  def non_opss_organisation
    { id: "def4eef8-1a33-4322-8b8c-fc7fa95a2e3b", name: "Organisation 1", path: "/Organisations/Organisation 1" }
  end

  def opss_organisation
    { id: "1a612aea-1d3d-47ee-8c3a-76b4448bb97b", name: "Office of Product Safety and Standards", path: "/Organisations/Organisation 2" }
  end

  def set_default_group_memberships
    add_user_to_opss_team user_id: @users[0][:id], team_id: @teams[0][:id]
    add_user_to_opss_team user_id: @users[1][:id], team_id: @teams[0][:id]
    add_user_to_opss_team user_id: @users[1][:id], team_id: @teams[1][:id]
    add_user_to_opss_team user_id: @users[2][:id], team_id: @teams[1][:id]
    add_user_to_opss_team user_id: @users[3][:id], team_id: @teams[2][:id]
    add_user_to_opss_team user_id: @users[3][:id], team_id: @teams[3][:id]
    set_kc_user_as_non_opss @users[4][:id]
    add_user_to_team @users[4][:id], @teams[4][:id]
  end

  # This is a private method which updates the KC mocking without modifying the User collection directly
  def set_kc_user_as_opss(user_id)
    # Keycloak bases this role on the group membership
    set_kc_user_group(user_id, opss_organisation[:id])
    roles = @keycloak_client_instance.get_user_roles(user_id)
    roles << :opss_user
    allow(@keycloak_client_instance).to receive(:get_user_roles).with(user_id).and_return(roles)
    User.load_from_keycloak
  end

  # This is a private method which updates the KC mocking without modifying the User collection directly
  def set_kc_user_as_non_opss(user_id)
    # Keycloak bases this role on the group membership
    clear_kc_user_groups(user_id)
    set_kc_user_group(user_id, non_opss_organisation[:id])

    roles = @keycloak_client_instance.get_user_roles(user_id)
    roles.delete(:opss_user)
    allow(@keycloak_client_instance).to receive(:get_user_roles).with(user_id).and_return(roles)
    User.load_from_keycloak
  end

  def add_user_to_team(user_id, team_id)
    # Using Class constructor here to create a sensible id
    # Not actually affecting the TeamUser collection
    @team_users.push id: SecureRandom.uuid, user_id: user_id, team_id: team_id
    set_kc_user_group(user_id, team_id)
  end

  def set_kc_user_group(user_id, group_id)
    mock_user = @users.find { |u| u[:id] == user_id }
    mock_user[:groups] ||= []
    mock_user[:groups].push group_id
    User.load_from_keycloak
  end

  def clear_kc_user_groups(user_id)
    mock_user = @users.find { |u| u[:id] == user_id }
    mock_user[:groups] = []
    User.load_from_keycloak
  end

  def all_teams
    [
      { id: "aaaaeef8-1a33-4322-8b8c-fc7fa95a2e3b", name: "Team 1", path: "/Organisations/Office of Product Safety and Standards/Team 1", organisation_id: "1a612aea-1d3d-47ee-8c3a-76b4448bb97b" },
      { id: "eeeeeef8-1a33-4322-8b8c-fc7fa95a2e3b", name: "Team 2", path: "/Organisations/Office of Product Safety and Standards/Team 2", organisation_id: "1a612aea-1d3d-47ee-8c3a-76b4448bb97b" },
      { id: "bbbbeef8-1a33-4322-8b8c-fc7fa95a2e3b", name: "Team 3", path: "/Organisations/Office of Product Safety and Standards/Team 3", organisation_id: "1a612aea-1d3d-47ee-8c3a-76b4448bb97b" },
      { id: "cccceef8-1a33-4322-8b8c-fc7fa95a2e3b", name: "Team 4", path: "/Organisations/Office of Product Safety and Standards/Team 4", organisation_id: "1a612aea-1d3d-47ee-8c3a-76b4448bb97b", team_recipient_email: "team@example.com" },
      { id: "ddddeef8-1a33-4322-8b8c-fc7fa95a2e3b", name: "Organisation 1 team", path: "/Organisations/Organisation 1/Organisation 1 team", organisation_id: "def4eef8-1a33-4322-8b8c-fc7fa95a2e3b" }
    ]
  end

  def format_user_for_get_users(users)
    users.map { |user| { id: user[:id], email: user[:email], firstName: user[:name], lastName: "n/a" } }.to_json
  end

  def stub_user_management
    allow(@keycloak_client_instance).to receive(:add_user_to_team), &method(:add_user_to_team)
    allow(@keycloak_client_instance).to receive(:create_user) do |email|
      user = { id: SecureRandom.uuid, email: email, username: email }
      @users.push user
      allow(@keycloak_client_instance).to receive(:get_user).and_return user
    end
    allow(@keycloak_client_instance).to receive(:send_required_actions_welcome_email).and_return(true)
  end

  def restore_user_management
    allow(@keycloak_client_instance).to receive(:add_user_to_team).and_call_original
    allow(@keycloak_client_instance).to receive(:create_user).and_call_original
    allow(@keycloak_client_instance).to receive(:send_required_actions_welcome_email).and_call_original
    allow(@keycloak_client_instance).to receive(:get_user).and_call_original
  end
end
