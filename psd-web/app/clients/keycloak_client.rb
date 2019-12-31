module Keycloak
  module Client
    def self.get_installation
      @realm = "opss"
      @auth_server_url = ENV.fetch("KEYCLOAK_AUTH_URL")
      @client_id = ENV.fetch("KEYCLOAK_CLIENT_ID")
      @secret = ENV.fetch("KEYCLOAK_CLIENT_SECRET")
      openid_configuration
    end
  end

  module Internal
    def self.token
      @token ||= KeycloakToken.new(Keycloak::Client.configuration["token_endpoint"])
    end

    def self.get_group(group_id)
      request_uri = Keycloak::Admin.full_url("groups/#{group_id}")
      Keycloak.generic_request(token.access_token, request_uri, nil, nil, "GET")
    end

    def self.get_user_groups(query_parameters = nil)
      request_uri = Keycloak::Client.auth_server_url + "/realms/#{Keycloak::Client.realm}/admin/user-groups"
      Keycloak.generic_request(token.access_token, request_uri, query_parameters, nil, "GET")
    end

    def self.add_user_group(user_id, group_id)
      request_uri = Keycloak::Admin.full_url("users/#{user_id}/groups/#{group_id}")
      Keycloak.generic_request(token.access_token, request_uri, nil, nil, "PUT")
    end

    def self.create_user(user_rep)
      request_uri = Keycloak::Admin.full_url("users/")
      Keycloak.generic_request(token.access_token, request_uri, nil, user_rep, "POST")
    end

    def self.execute_actions_email(user_id, actions, client_id, redirect_uri)
      request_uri = Keycloak::Admin.full_url("users/#{user_id}/execute-actions-email")
      query_params = { client_id: client_id, redirect_uri: redirect_uri }
      Keycloak.generic_request(token.access_token, request_uri, query_params, actions, "PUT")
    end

    def self.get_user_roles(user_id)
      client = JSON Keycloak::Admin.get_clients({ clientId: ENV.fetch("KEYCLOAK_CLIENT_ID") }, token.access_token)
      request_uri = Keycloak::Admin.full_url("users/#{user_id}/role-mappings/clients/#{client[0]['id']}/composite")
      Keycloak.generic_request(token.access_token, request_uri, nil, nil, "GET")
    end

    def self.get_groups(query_parameters = nil)
      request_uri = Keycloak::Admin.full_url("groups/")
      Keycloak.generic_request(token.access_token, request_uri, query_parameters, nil, "GET")
    end

    def self.get_users(query_parameters = nil)
      request_uri = Keycloak::Admin.full_url("users/")
      Keycloak.generic_request(token.access_token, request_uri, query_parameters, nil, "GET")
    end
  end
end

class KeycloakClient
  include Singleton

  def client
    return @client if @client

    @client = Keycloak::Client
    @client.get_installation
    @client
  end

  def admin
    @admin ||= Keycloak::Admin
  end

  def internal
    @internal ||= Keycloak::Internal
  end

  def reset
    @client = @admin = @internal = nil
  end

  def all_users
    # KC defaults to max:100, while we need all users. 1000000 seems safe, at least for the time being
    users = internal.get_users(max: 1000000)

    user_groups = all_user_groups

    JSON.parse(users).map do |user|
      { id: user["id"], email: user["email"], name: user["firstName"], groups: user_groups[user["id"]] }
    end
  end

  def all_organisations
    organisations = all_groups.find { |group| group["name"] == "Organisations" }
    organisations["subGroups"].reject(&:blank?).map { |h| h.slice("id", "name", "path").symbolize_keys }
  end

  # @param org_ids specifies teams for which organisations should be returned. This allows us to avoid creating
  # orphaned team entities
  def all_teams(org_ids)
    all_groups.find { |group| group["name"] == "Organisations" }["subGroups"]
      .reject(&:blank?)
      .select { |organisation| org_ids.include?(organisation["id"]) }
      .flat_map(&method(:extract_teams_from_organisation))
  end

  def registration_url(redirect_uri)
    params = URI.encode_www_form(client_id: Keycloak::Client.client_id, response_type: "code", redirect_uri: redirect_uri)
    Keycloak::Client.auth_server_url + "/realms/#{Keycloak::Client.realm}/protocol/openid-connect/registrations?#{params}"
  end

  def login_url(redirect_uri)
    client.url_login_redirect(redirect_uri)
  end

  def user_account_url
    client.url_user_account
  end

  def exchange_code_for_token(code, redirect_uri)
    client.get_token_by_code(code, redirect_uri)
  end

  def exchange_refresh_token_for_token(refresh_token)
    client.get_token_by_refresh_token(refresh_token)
  end

  def logout(refresh_token)
    client.logout("", refresh_token)
  end

  def user_signed_in?(access_token)
    client.user_signed_in?(access_token)
  end

  def user_info(access_token)
    response = client.get_userinfo(access_token)
    user = JSON.parse(response)
    { id: user["sub"], email: user["email"], groups: user["groups"], name: user["given_name"] }
  end

  def get_user_roles(user_id)
    roles = JSON.parse(internal.get_user_roles(user_id))
    roles.map { |role| role["name"].to_sym }
  end

  def add_user_to_team(user_id, group_id)
    internal.add_user_group user_id, group_id
  end

  def create_user(email)
    internal.create_user email: email, username: email, enabled: true
  end

  def get_user(email)
    JSON.parse(internal.get_users(email: email)).first.symbolize_keys
  end

  def send_required_actions_welcome_email(user_id, redirect_uri)
    required_actions = %w(sms_auth_check_mobile UPDATE_PASSWORD UPDATE_PROFILE VERIFY_EMAIL)
    internal.execute_actions_email user_id, required_actions, "psd-app", redirect_uri
  end

private

  def group_attributes(group_id)
    cache_key = "keycloak_group_#{group_id}".to_sym
    response = Rails.cache.fetch(cache_key, expires_in: cache_period) do
      Keycloak::Internal.get_group(group_id)
    end
    JSON.parse(response)["attributes"] || {}
  end

  def all_user_groups
    response = Keycloak::Internal.get_user_groups(max: 1000000)
    JSON.parse(response).collect { |user| [user["id"], user["groups"]] }.to_h
  end

  def all_groups
    # KC has a default max for users of 100. The docs don't mention a default for groups, but for prudence
    # and ease of mind, we're ensuring a high-enough cap here, too
    response = Keycloak::Internal.get_groups(max: 1000000)
    JSON.parse(response)
  end

  def cache_period
    5.minutes
  end

  def extract_teams_from_organisation(organisation)
    organisation["subGroups"].reject(&:blank?).map do |team|
      team_recipient_email = group_attributes(team["id"])["teamRecipientEmail"]&.first
      { id: team["id"],
        name: team["name"],
        path: team["path"],
        organisation_id: organisation["id"],
        team_recipient_email: team_recipient_email }
    end
  end
end
