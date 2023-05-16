class NotifyingCountryForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :country, :string
  attribute :notifying_country_uk, :string
  attribute :notifying_country_overseas, :string
  attribute :overseas_or_uk, :string

  validate :notifying_country_has_been_selected

  def self.from(investigation)
    new(country: investigation.notifying_country)
  end

private

  def notifying_country_has_been_selected
    return errors.add(:overseas_or_uk, :inclusion) if overseas_or_uk.blank?

    notifying_country_overseas_has_been_selected if overseas_or_uk == "overseas"
    notifying_country_uk_has_been_selected if overseas_or_uk == "uk"
  end

  def notifying_country_overseas_has_been_selected
    errors.add(:notifying_country_overseas, :inclusion) if notifying_country_overseas.blank?
  end

  def notifying_country_uk_has_been_selected
    errors.add(:notifying_country_uk, :inclusion) if notifying_country_uk.blank?
  end
end
