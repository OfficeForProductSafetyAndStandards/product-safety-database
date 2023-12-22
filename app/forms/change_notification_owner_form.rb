class ChangeNotificationOwnerForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :owner_id
  attribute :owner_rationale

  validates_presence_of :owner_id
  validate :new_owner_must_be_active_user_or_team, if: -> { owner_id.present? }

  def owner
    user || team
  end

private

  def new_owner_must_be_active_user_or_team
    errors.add(:owner_id, :not_found) unless owner
  end

  def user
    @user ||= User.active.find_by(id: owner_id)
  end

  def team
    @team ||= Team.find_by(id: owner_id)
  end
end
