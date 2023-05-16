class OverseasRegulatorForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :is_from_overseas_regulator, :boolean, default: nil
  attribute :overseas_regulator_country, :string

  validates :is_from_overseas_regulator, inclusion: { in: [true, false] }
  validates :overseas_regulator_country, inclusion: { in: Country.overseas_regulator_countries.map(&:last) }, if: -> { is_from_overseas_regulator }

  def self.from(investigation)
    new(is_from_overseas_regulator: investigation.is_from_overseas_regulator, overseas_regulator_country: investigation.overseas_regulator_country)
  end
end
