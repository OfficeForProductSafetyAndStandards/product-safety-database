class RiskAssessment < ApplicationRecord
  belongs_to :investigation

  belongs_to :assessed_by_team, class_name: :Team, optional: true
  belongs_to :assessed_by_business, class_name: :Business, optional: true

  belongs_to :added_by_user, class_name: :User
  belongs_to :added_by_team, class_name: :Team

  has_many :risk_assessed_products
  has_many :products, through: :risk_assessed_products

  has_one_attached :risk_assessment_file

  enum risk_level: {
    serious: "serious",
    high: "high",
    medium: "medium",
    low: "low",
    other: "other"
  }
end
