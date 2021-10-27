class RemoveUserForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :remove, :string, default: nil
  attribute :user_id, :string, default: nil

  validates :remove, inclusion: { in: %w[yes no], message: "Select an option" }
  validates :user_id, presence: true
end
