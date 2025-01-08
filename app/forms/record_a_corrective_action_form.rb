class RecordACorrectiveActionForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :add_another_corrective_action
  validates :add_another_corrective_action, presence: true
end
