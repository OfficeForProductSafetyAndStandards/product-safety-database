class AddBusinessDetailsForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :trading_name, :string
  attribute :legal_name, :string
  attribute :company_number, :string
  attribute :business_id

  def initialize(attributes = {})
    super
    trim_spaces
  end

  validates :trading_name, presence: true

private

  def trim_spaces
    self.legal_name = legal_name&.squish
    self.trading_name = trading_name&.squish
    self.company_number = company_number&.squish
  end
end
