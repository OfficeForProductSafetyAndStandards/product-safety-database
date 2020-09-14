class Team < ApplicationRecord
  include Deletable
  include TeamCollaboratorInterface

  belongs_to :organisation
  has_many :users, dependent: :restrict_with_exception

  has_many :collaborations, dependent: :destroy, as: :collaborator
  has_many :collaboration_accesses, class_name: "Collaboration::Access", as: :collaborator

  has_many :owner_collaborations, class_name: "Collaboration::Access::OwnerTeam", as: :collaborator

  validates :name, presence: true

  def self.all_with_organisation
    all.includes(:organisation)
  end

  def display_name(*)
    name
  end

  def self.get_visible_teams(user)
    team_names = Rails.application.config.team_names["organisations"]["opss"]
    return where(name: team_names) if user.is_opss?

    where(name: team_names.first)
  end
end
