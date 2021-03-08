class NotifyingCountryForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :country, :string

  validates :country, presence: true
end
