class CaseNameForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :user_title, :string

  validates :user_title, presence: true
end
