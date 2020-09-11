class Team < ApplicationRecord
  include TeamCollaboratorInterface

  belongs_to :organisation
  has_many :users, dependent: :restrict_with_exception

  has_many :collaborations, dependent: :destroy, as: :collaborator

  validates :name, presence: true

  def self.all_with_organisation
    all.includes(:organisation)
  end

  def self.not_deleted
    where(deleted_at: nil)
  end

  def deleted?
    deleted_at.present?
  end

  def mark_as_deleted!
    return if deleted?

    update!(deleted_at: Time.current)
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
