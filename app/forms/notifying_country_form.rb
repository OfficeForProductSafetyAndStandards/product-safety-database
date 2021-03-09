class NotifyingCountryForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :country, :string

  validates :country, presence: true

  def self.from(investigation)
    new(country: investigation.notifying_country)
  end
end
