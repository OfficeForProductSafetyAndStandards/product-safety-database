class OverseasRegulatorForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :is_from_overseas_regulator, :boolean, default: nil
  attribute :notifying_country, :string

  validates :is_from_overseas_regulator, inclusion: { in: [true, false] }
  validates :notifying_country, inclusion: { in: Country.overseas_countries.map(&:last) }, if: -> { is_from_overseas_regulator }

  def self.from(investigation)
    new(is_from_overseas_regulator: investigation.is_from_overseas_regulator, notifying_country: investigation.notifying_country)
  end
end
