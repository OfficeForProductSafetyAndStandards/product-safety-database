class RemoveUserForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :remove, :string, default: nil
  attribute :user_id, :string, default: nil

  validates :remove, inclusion: { in: %w[yes no], message: "Select yes if you want to remove the team member from your team" }
  validates :user_id, presence: true
end
