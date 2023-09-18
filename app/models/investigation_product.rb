class InvestigationProduct < ApplicationRecord
  belongs_to :investigation
  belongs_to :product

  enum affected_units_status: {
    "exact" => "exact",
    "approx" => "approx",
    "unknown" => "unknown",
    "not_relevant" => "not_relevant"
  }

  default_scope { order(created_at: :asc) }

  has_many :corrective_actions, dependent: :destroy
  has_many :tests, dependent: :destroy
  has_many :test_results, class_name: "Test::Result", dependent: :destroy
  has_many :unexpected_events
  has_many :risk_assessed_products
  has_many :risk_assessments, through: :risk_assessed_products
  has_many :prism_associated_products, foreign_key: :product_id
  has_many :prism_associated_investigation_products, foreign_key: :product_id
  has_many :prism_risk_assessments_via_product, through: :prism_associated_products, class_name: "PrismRiskAssessment", source: :prism_risk_assessment
  has_many :prism_associated_investigations, through: :prism_associated_investigation_products
  has_many :prism_risk_assessments_via_investigations, through: :prism_associated_investigations, class_name: "PrismRiskAssessment", source: :prism_risk_assessment
  has_many :ucr_numbers

  belongs_to :added_by_user, class_name: :User, optional: true
  belongs_to :owning_team, class_name: "Team", inverse_of: :owned_products, optional: true

  redacted_export_with :id, :affected_units_status, :batch_number, :created_at,
                       :customs_code, :investigation_id, :number_of_affected_units,
                       :product_id, :updated_at

  accepts_nested_attributes_for :ucr_numbers, allow_destroy: true, reject_if: proc { |l| l[:number].blank? }

  delegate :name, to: :product

  def product
    investigation_closed_at ? super.paper_trail.version_at(investigation_closed_at) || super : super
  end

  def prism_risk_assessments
    prism_risk_assessments_via_product + prism_risk_assessments_via_investigations
  end

  def supporting_information
    tests + corrective_actions + unexpected_events + risk_assessments + prism_risk_assessments
  end

  def psd_ref
    product.psd_ref timestamp: investigation_closed_at&.to_i, investigation_was_closed: investigation_closed_at.present?
  end
end
