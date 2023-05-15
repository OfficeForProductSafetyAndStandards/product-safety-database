class NotifyingCountryForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :country, :string
  attribute :notifying_country_uk, :string
  attribute :notifying_country_overseas, :string
  attribute :overseas_or_uk, :string

  # validates :country, inclusion: { in: Country.notifying_countries.map(&:last) }
  validate :country_thing

  def self.from(investigation)
    new(country: investigation.notifying_country)
  end

private

  def country_thing
    errors.add(:overseas_or_uk, :inclusion) if overseas_or_uk.blank?
    errors.add(:notifying_country_overseas, :inclusion) if notifying_country_overseas.blank? && overseas_or_uk == "overseas"
    errors.add(:notifying_country_uk, :inclusion) if notifying_country_uk.blank? && overseas_or_uk == "uk"
  end
end
