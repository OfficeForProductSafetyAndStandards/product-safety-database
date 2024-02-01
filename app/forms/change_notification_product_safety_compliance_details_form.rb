class ChangeNotificationProductSafetyComplianceDetailsForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :unsafe, :boolean
  attribute :noncompliant, :boolean
  attribute :primary_hazard, :string
  attribute :primary_hazard_description, :string
  attribute :noncompliance_description, :string
  attribute :is_from_overseas_regulator, :boolean
  attribute :overseas_regulator_country, :string
  attribute :add_reference_number, :boolean
  attribute :reference_number, :string
  attribute :safe_and_compliant, :boolean # Whether the notification has already been marked as "safe and compliant"
  attribute :current_user

  validate :at_least_one_of_unsafe_or_noncompliant, unless: -> { safe_and_compliant }
  validates :primary_hazard, :primary_hazard_description, presence: true, if: -> { unsafe }, unless: -> { safe_and_compliant }
  validates :noncompliance_description, presence: true, if: -> { noncompliant }, unless: -> { safe_and_compliant }
  validates :is_from_overseas_regulator, inclusion: [true, false]
  validates :overseas_regulator_country, inclusion: { in: Country.overseas_countries.map(&:last) }, if: -> { is_from_overseas_regulator }
  validates :add_reference_number, inclusion: [true, false]
  validates :reference_number, presence: true, if: -> { add_reference_number }
  validates :primary_hazard_description, :noncompliance_description, length: { maximum: 10_000 }

  def at_least_one_of_unsafe_or_noncompliant
    errors.add(:unsafe, :blank) if unsafe.nil? && noncompliant.nil?
  end
end
