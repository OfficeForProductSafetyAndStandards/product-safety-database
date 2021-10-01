class BusinessForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Dirty

  attribute :trading_name
  attribute :legal_name
  attribute :company_number
  attribute :investigation_id

  validates_presence_of  :trading_name
end
