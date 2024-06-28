class ChangeNotificationDetailsForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :user_title, :string
  attribute :description, :string
  attribute :reported_reason, :string
  attribute :current_user
  attribute :notification_id

  validates :user_title, :reported_reason, presence: true, length: {maximum: 100}
  validates :description, length: { maximum: 10_000 }
  validate :unique_user_title_within_team

  def unique_user_title_within_team
    return unless user_title

    notification_with_same_title = Investigation.where(user_title:, is_closed: false).where.not(id: notification_id)
                                                .joins(:collaborations).where(collaborations: { collaborator_id: current_user.team.id })
    errors.add(:user_title, "The notification name has already been used in another open notification by your team") unless notification_with_same_title.empty?
  end
end
