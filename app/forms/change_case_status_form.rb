class ChangeCaseStatusForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :new_status
  attribute :rationale

  validates_inclusion_of :new_status, in: %w[open closed]
end
