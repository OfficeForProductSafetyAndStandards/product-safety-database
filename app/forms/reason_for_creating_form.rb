class ReasonForCreatingForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :case_is_safe, :string

  validates :case_is_safe, inclusion: { in: ['yes', 'no'] }
end
