class PrismRiskAssessment < ApplicationRecord
  # This model is only used for the PRISM risk assessment
  # dashboard inside PSD and cannot be used to create new
  # PRISM risk assessments. Creation and editing is handled
  # by the PRISM engine using the `Prism::RiskAssessment` model.
  def readonly?
    true
  end

  has_one :prism_product_market_detail, foreign_key: "risk_assessment_id"
  has_many :prism_harm_scenarios, foreign_key: "risk_assessment_id"
  has_many :prism_associated_investigations, foreign_key: "risk_assessment_id"
  has_many :prism_associated_products, foreign_key: "risk_assessment_id"
  has_many :prism_associated_investigation_products, through: :prism_associated_investigations, foreign_key: "risk_assessment_id"

  scope :for_user, ->(user) { where(created_by_user_id: user.id) }
  scope :for_team, ->(team) { where(created_by_user_id: team.users.pluck(:id)) }
  scope :draft, -> { where.not(state: "submitted") }
  scope :submitted, -> { where(state: "submitted") }

  def product_name
    if prism_associated_investigations.present? && prism_associated_investigation_products.present?
      prism_associated_investigations.first.prism_associated_investigation_products.first.product.name
    elsif prism_associated_products.present?
      prism_associated_products.first.product.name
    else
      "Unknown product"
    end
  end

  def product_id
    if prism_associated_investigations.present? && prism_associated_investigation_products.present?
      prism_associated_investigations.first.prism_associated_investigation_products.first.product.id
    elsif prism_associated_products.present?
      prism_associated_products.first.product.id
    end
  end

  def user_and_organisation
    user = User.find(created_by_user_id)
    [user.name, user.organisation.name]
  end
end
