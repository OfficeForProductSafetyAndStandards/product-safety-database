module Keycloak
  module Client
    def self.get_installation
      @realm = "opss"
      @auth_server_url = ENV["KEYCLOAK_AUTH_URL"]
      @client_id = ENV["KEYCLOAK_CLIENT_ID"]
      @secret = ENV["KEYCLOAK_CLIENT_SECRET"]
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
  end
end

class KeycloakClient
  include Singleton

  def initialize
    # The gem we're using has its api split across these three classes
    @client = Keycloak::Client
    @admin = Keycloak::Admin
    @internal = Keycloak::Internal
    super
  end

  def all_users
    # KC defaults to max:100, while we need all users. 1000000 seems safe, at least for the time being
    users = @internal.get_users(max: 1000000)

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
  def all_teams(org_ids, force: false)
    org_ids_set = org_ids.to_set
    Rails.cache.delete(:keycloak_teams) if force
    Rails.cache.fetch(:keycloak_teams, expires_in: cache_period) do
      all_groups.find { |group| group["name"] == "Organisations" }["subGroups"]
          .reject(&:blank?)
          .select { |organisation| org_ids_set.include? organisation["id"] }
          .flat_map(&method(:extract_teams_from_organisation))
    end
  end

  # @param team_ids specifies teams we know about. This allows us to avoid linking to ghost team entities
  def all_team_users(user_ids, team_ids, force: false)
    user_ids_set = user_ids.to_set
    team_ids_set = team_ids.to_set
    Rails.cache.delete(:keycloak_team_users) if force
    Rails.cache.fetch(:keycloak_team_users, expires_in: cache_period) do
      user_groups = all_user_groups

      # We set ids manually because if we don't ActiveHash will use 'next_id' method when computing @records,
      # which calls TeamUser.all, and gets into an infinite loop
      team_users = []
      id = 1
      user_ids_set.reject(&:blank?).each do |user_id|
        user_groups[user_id].reject(&:blank?).each do |group|
          team_users << { team_id: group, user_id: user_id, id: id } if team_ids_set.include? group
          id += 1
        end
      end
      team_users
    end
  end

  def registration_url(redirect_uri)
    params = URI.encode_www_form(client_id: Keycloak::Client.client_id, response_type: "code", redirect_uri: redirect_uri)
    Keycloak::Client.auth_server_url + "/realms/#{Keycloak::Client.realm}/protocol/openid-connect/registrations?#{params}"
  end

  def login_url(redirect_uri)
    @client.url_login_redirect(redirect_uri)
  end

  def user_account_url
    @client.url_user_account
  end

  def exchange_code_for_token(code, redirect_uri)
    @client.get_token_by_code(code, redirect_uri)
  end

  def exchange_refresh_token_for_token(refresh_token)
    @client.get_token_by_refresh_token(refresh_token)
  end

  def logout(refresh_token)
    @client.logout("", refresh_token)
  end

  def user_signed_in?(access_token)
    @client.user_signed_in?(access_token)
  end

  def user_info(access_token)
    response = @client.get_userinfo(access_token)
    user = JSON.parse(response)
    { id: user["sub"], email: user["email"], groups: user["groups"], name: user["given_name"] }
  end

  def get_user_roles(user_id)
    roles = JSON.parse(@internal.get_user_roles(user_id))
    roles.map { |role| role["name"].to_sym }
  end

  def add_user_to_team(user_id, group_id)
    @internal.add_user_group user_id, group_id
  end

  def create_user(email)
    @internal.create_user email: email, username: email, enabled: true
  end

  def get_user(email)
    @internal.get_user_info(email).first.symbolize_keys
  end

  def send_required_actions_welcome_email(user_id, redirect_uri)
    required_actions = %w(sms_auth_check_mobile UPDATE_PASSWORD UPDATE_PROFILE VERIFY_EMAIL)
    @internal.execute_actions_email user_id, required_actions, "psd-app", redirect_uri
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
