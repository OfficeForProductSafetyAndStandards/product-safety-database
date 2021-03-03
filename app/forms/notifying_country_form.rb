class NotifyingCountryForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :country, :string, default: nil

  validates :country, presence: true
end
