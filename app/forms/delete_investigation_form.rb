class DeleteInvestigationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :deleting_user
  attribute :investigation

  validates :deleting_user, presence: true
  validates :investigation, presence: true
end
