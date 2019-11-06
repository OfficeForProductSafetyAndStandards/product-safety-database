class User < ApplicationRecord
  belongs_to :organisation

  has_many :activities, dependent: :nullify
  has_many :investigations, dependent: :nullify, as: :assignable
  has_many :user_sources, dependent: :destroy

  has_many :team_users, dependent: :nullify
  has_many :teams, through: :team_users

  validates :id, presence: true, uuid: true

  attr_accessor :access_token
  attr_writer :roles

  def teams
    # Ensure we're serving up-to-date relations (modulo caching)
    TeamUser.load
    # has_many through seems not to work with ActiveHash
    # It's not well documented but the same fix has been suggested here: https://github.com/zilkey/active_hash/issues/25
    team_users.map(&:team)
  end

  def self.create_and_send_invite(email_address, team, redirect_url)
    KeycloakClient.instance.create_user(email_address)

    keycloak_user = KeycloakClient.instance.get_user(email_address)

    # Create the user in the local cache database so that we don't have to wait until the next sync
    user = create(id: keycloak_user[:id], email: email_address)
    team.add_user(user)

    KeycloakClient.instance.send_required_actions_welcome_email keycloak_user[:id], redirect_url
  end

  def self.resend_invite(email_address, _team, redirect_url)
    user_id = KeycloakClient.instance.get_user(email_address)[:id]
    KeycloakClient.instance.send_required_actions_welcome_email user_id, redirect_url
  end

  def self.find_or_create(attributes)
    find_or_create_by(id: attributes[:id]) do |user|
      groups = attributes.delete(:groups)
      organisation = Organisation.find_by(path: groups)
      create(attributes.merge(organisation_id: organisation&.id))
    end
  end

  def self.load_from_keycloak(users = KeycloakClient.instance.all_users)
    # We're not interested in users not belonging to an organisation, as that means they are not PSD users
    # - however, checking this based on permissions would require a request per user
    users.map do |user|
      teams = Team.where(id: user[:groups])

      # Filters out user groups which aren't related to PSD. User may belong directly to an Organisation, or indirectly via a Team
      organisation = Organisation.find_by(id: user[:groups]) || Organisation.find_by(id: teams.first&.organisation_id)
      user[:organisation] = organisation

      user
    end.reject { |user| user[:organisation_id].blank? }

    users.each do |user|
      record = find_or_create_by(id: user[:id])
      record.update(user.slice(:name, :email, :organisation))
    end
  end

  def self.current
    RequestStore.store[:current_user]
  end

  def self.current=(user)
    RequestStore.store[:current_user] = user
  end

  def has_role?(role)
    roles.include?(role)
  end

  def roles
    @roles ||= Rails.cache.fetch("user_roles_#{id}", expires_in: 30.minutes) do
      KeycloakClient.instance.get_user_roles(id)
    end
  end

  def display_name(ignore_visibility_restrictions: false)
    display_name = name
    can_display_teams = ignore_visibility_restrictions || (organisation.present? && organisation.id == User.current.organisation_id)
    can_display_teams = can_display_teams && teams.any?
    membership_display = can_display_teams ? team_names : organisation&.name
    display_name += " (#{membership_display})" if membership_display.present?
    display_name
  end

  def team_names
    teams.map(&:name).join(", ")
  end

  def assignee_short_name
    if organisation.present? && organisation.id != User.current.organisation_id
      organisation.name
    else
      name
    end
  end

  def is_psd_user?
    has_role? :psd_user
  end

  def is_psd_admin?
    has_role? :psd_admin
  end

  def is_opss?
    has_role? :opss_user
  end

  def is_team_admin?
    has_role? :team_admin
  end

  def self.get_assignees(except: [])
    users_to_exclude = Array(except)
    self.all - users_to_exclude
  end

  def self.get_team_members(user:)
    users = [].to_set
    user.teams.each do |team|
      team.users.each do |team_member|
        users << team_member
      end
    end
    users
  end

  def has_viewed_introduction!
    update has_viewed_introduction: true
  end

  def has_accepted_declaration!
    update has_accepted_declaration: true
  end

  def has_been_sent_welcome_email!
    update has_been_sent_welcome_email: true
  end

private

  def current_user?
    User.current&.id == id
  end
end
