class AddBusinessDetailsForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :trading_name, :string
  attribute :legal_name, :string
  attribute :company_number, :string
  attribute :business_id

  validates :trading_name, presence: true
end
