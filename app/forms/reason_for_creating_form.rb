class ReasonForCreatingForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :case_is_safe, :string
  attribute :product_id, :integer

  validates :case_is_safe, inclusion: { in: %w[yes no] }
end
