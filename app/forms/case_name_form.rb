class CaseNameForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :user_title, :string
  attribute :current_user

  validates :user_title, presence: true
  validate :unique_user_title_within_team

  def unique_user_title_within_team
    return unless user_title

    case_with_same_title = Investigation.where(user_title:, is_closed: false)
                                        .joins(:collaborations).where(collaborations: { collaborator_id: current_user.team.id })
    errors.add(:user_title, "The notification name has already been used in an open notification by your team") unless case_with_same_title.empty?
  end
end
