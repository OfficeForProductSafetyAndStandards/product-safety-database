class RiskAssessment < ApplicationRecord
  belongs_to :investigation

  belongs_to :assessed_by_team, class_name: :Team, optional: true
  belongs_to :assessed_by_business, class_name: :Business, optional: true

  belongs_to :added_by_user, class_name: :User
  belongs_to :added_by_team, class_name: :Team

  has_many :risk_assessed_products
  has_many :investigation_products, through: :risk_assessed_products

  has_one_attached :risk_assessment_file

  validates :assessed_on, presence: true

  validate :assessed_on_cannot_be_in_future
  validate :assessed_on_cannot_be_older_than_1970

  validate :at_least_one_product_associated

  validates :risk_level, presence: true

  validates :custom_risk_level, presence: true, if: -> { other? }
  validates :custom_risk_level, absence: true, unless: -> { other? }

  # Exactly 1 of team, business or "other" required
  validates :assessed_by_business, absence: true, if: -> { assessed_by_team }
  validates :assessed_by_other, presence: true, if: -> { assessed_by_team.nil? && assessed_by_business.nil? }
  validates :assessed_by_other, absence: true, if: -> { assessed_by_team || assessed_by_business }

  enum risk_level: {
    serious: "serious",
    high: "high",
    medium: "medium",
    low: "low",
    other: "other"
  }

  redacted_export_with :id, :added_by_team_id, :added_by_user_id, :assessed_by_business_id,
                       :assessed_by_other, :assessed_by_team_id, :assessed_on, :created_at,
                       :custom_risk_level, :details, :investigation_id, :risk_level, :updated_at

private

  def assessed_on_cannot_be_in_future
    if assessed_on.is_a?(Date) && assessed_on > Time.zone.today

      errors.add(:assessed_on, :in_future)
    end
  end

  def assessed_on_cannot_be_older_than_1970
    if assessed_on.is_a?(Date) && assessed_on < Date.parse("1970-01-01")
      errors.add(:assessed_on, :too_old)
    end
  end

  def at_least_one_product_associated
    return unless investigation_product_ids.to_a.empty?

    errors.add(:products, :blank)
  end
end
