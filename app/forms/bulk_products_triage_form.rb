class BulkProductsTriageForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :compliance_and_safety
  attribute :hazard_description

  validates :compliance_and_safety, inclusion: { in: %w[unsafe non_compliant mixed] }
  validates :hazard_description, presence: true, length: { maximum: 10_000 }, if: -> { compliance_and_safety == "non_compliant" }
end
