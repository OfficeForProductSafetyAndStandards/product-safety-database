class Team < ApplicationRecord
  belongs_to :organisation

  has_and_belongs_to_many :users

  has_many :investigations, dependent: :nullify, as: :assignable

  validates :id, presence: true, uuid: true
  validates :name, presence: true
  validates :path, presence: true

  def add_user(user)
    users << user
  end

  def self.load_from_keycloak(teams = KeycloakClient.instance.all_teams(Organisation.ids))
    teams.each do |team|
      begin
        record = find_or_create_by!(id: team[:id]) do |new_record|
          new_record.name = team[:name]
          new_record.path = team[:path]
          new_record.organisation_id = team[:organisation_id]
        end

        record.update!(team.slice(:name, :path, :team_recipient_email, :organisation_id))
      rescue ActiveRecord::ActiveRecordError => e
        if Rails.env.production?
          Raven.capture_exception(e)
        else
          raise(e)
        end
      end
    end

    self.ensure_names_up_to_date
  end

  def self.all_with_organisation
    all.includes(:organisation)
  end

  def display_name(ignore_visibility_restrictions: false, current_user: User.current)
    return name if (current_user && (current_user.organisation_id == organisation_id)) || ignore_visibility_restrictions

    organisation.name
  end

  def full_name
    display_name
  end

  def self.ensure_names_up_to_date
    return if Rails.env.test?

    missing = Rails.application.config.team_names["organisations"]["opss"] - all.collect(&:name)

    return true if missing.empty?

    raise "Team name #{missing.join(', ')} not found, if recently changed in Keycloak, please update important_team_names.yml"
  end

  def self.get_visible_teams(user)
    team_names = Rails.application.config.team_names["organisations"]["opss"]
    return where(name: team_names) if user.is_opss?

    where(name: team_names.first)
  end
end
