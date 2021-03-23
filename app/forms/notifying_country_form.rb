class NotifyingCountryForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :country, :string

  validates :country, inclusion: { in: Country.notifying_countries.map(&:last) }

  def self.from(investigation)
    new(country: investigation.notifying_country)
  end
end
