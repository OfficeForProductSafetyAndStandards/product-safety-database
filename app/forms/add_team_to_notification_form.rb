class AddTeamToNotificationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :team_id
  attribute :permission_level
  attribute :message
  attribute :include_message, :boolean, default: nil

  validates_presence_of :team_id
  validates_presence_of :permission_level
  validate :permission_level_valid?, if: -> { permission_level.present? }
  validates :message, presence: true, if: :include_message
  validates :include_message, inclusion: { in: [true, false] }

  def team
    @team ||= Team.find(team_id)
  end

  def collaboration_class
    Collaboration::Access.class_from_human_name(permission_level)
  end

private

  def permission_level_valid?
    errors.add(:permission_level, :blank) if collaboration_class.blank?
  end
end
