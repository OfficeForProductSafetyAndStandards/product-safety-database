class AddBusinessDetailsDuplicateForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :resolution, :string

  # Preserve the user's entered trading name and legal name
  # so they can be used if the user decides to continue with
  # manual entry.
  attribute :trading_name, :string
  attribute :legal_name, :string

  validates :resolution, presence: true
end
