class Team < ApplicationRecord
  belongs_to :organisation

  has_and_belongs_to_many :users

  has_many :investigations, dependent: :nullify, as: :assignable

  validates :name, presence: true

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

    raise "Team name #{missing.join(', ')} not found"
  end

  def self.get_visible_teams(user)
    team_names = Rails.application.config.team_names["organisations"]["opss"]
    return where(name: team_names) if user.is_opss?

    where(name: team_names.first)
  end
end
