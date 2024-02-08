class AddBusinessDetailsForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :trading_name, :string
  attribute :legal_name, :string

  validates :trading_name, presence: true
end
