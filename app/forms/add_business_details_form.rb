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
    self.legal_name = legal_name&.strip
    self.trading_name = trading_name&.strip
    self.company_number = company_number&.strip
  end
end
