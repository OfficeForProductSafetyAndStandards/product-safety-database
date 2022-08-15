class ReasonForCreatingForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :case_is_safe, :boolean

  validates :case_is_safe, presence: true
end
