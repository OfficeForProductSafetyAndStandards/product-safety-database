class NotifyingCountryForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :country, :string

  validates :country, presence: true

  def self.from(investigation)
    new(country: investigation.notifying_country)
  end
end
