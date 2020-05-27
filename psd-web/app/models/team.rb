class Team < ApplicationRecord
  belongs_to :organisation
  has_many :users, dependent: :restrict_with_exception
  has_many :investigations, dependent: :nullify, as: :owner
  has_many :collaborations, dependent: :destroy, as: :collaborator

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

  def self.get_visible_teams(user)
    team_names = Rails.application.config.team_names["organisations"]["opss"]
    return where(name: team_names) if user.is_opss?

    where(name: team_names.first)
  end
end
