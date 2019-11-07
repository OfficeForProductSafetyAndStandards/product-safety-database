class Team < ApplicationRecord
  belongs_to :organisation

  has_and_belongs_to_many :users

  has_many :investigations, dependent: :nullify, as: :assignable

  validates :id, presence: true, uuid: true

  def add_user(user)
    # Update the local cached team membership so the change appears immediately
    users << user

    KeycloakClient.instance.add_user_to_team(user.id, id)
  end

  def self.load_from_keycloak(teams = KeycloakClient.instance.all_teams(Organisation.ids))
    teams.each do |team|
      record = find_or_create_by(id: team[:id])
      record.update(team.slice(:name, :path, :team_recipient_email, :organisation_id))
    end

    self.ensure_names_up_to_date
  end

  def display_name(ignore_visibility_restrictions: false)
    return name if (User.current.organisation == organisation) || ignore_visibility_restrictions

    organisation.name
  end

  def full_name
    display_name
  end

  def assignee_short_name
    display_name
  end

  def self.ensure_names_up_to_date
    return if Rails.env.test?

    Rails.application.config.team_names["organisations"]["opss"].each do |name|
      found = false
      self.data.each { |team_data| found = found || team_data[:name] == name }
      raise "Team name #{name} not found, if recently changed in Keycloak, please update important_team_names.yml" unless found
    end

    true
  end

  def self.get_visible_teams(user)
    team_names = Rails.application.config.team_names["organisations"]["opss"]
    return where(name: team_names) if user.is_opss?

    where(name: team_names).limit(1)
  end
end
