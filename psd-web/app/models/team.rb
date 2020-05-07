class Team < ApplicationRecord
  belongs_to :organisation
  has_many :users, dependent: :restrict_with_exception
  has_many :investigations, dependent: :nullify, as: :owner

  validates :name, presence: true

  def self.all_with_organisation
    all.includes(:organisation)
  end

  def display_name(*)
    name
  end

  def team
    self
  end

  def in_same_team_as?(user)
    users.include?(user)
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
