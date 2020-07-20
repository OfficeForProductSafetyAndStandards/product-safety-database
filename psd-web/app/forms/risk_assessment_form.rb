class RiskAssessmentForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :investigation
  attribute :current_user

  attribute :assessed_on
  attribute :risk_level
  attribute :custom_risk_level

  attribute :assessed_by
  attribute :assessed_by_team_id
  attribute :assessed_by_business_id
  attribute :assessed_by_other

  attribute :product_ids

  attribute :risk_assessment_file

  attribute :details

  validates :assessed_on, presence: true
  validates :risk_level, presence: true

  validates :risk_assessment_file, presence: true

  validates :assessed_by, presence: true
  validate :at_least_one_product_associated

  def risk_levels
    {
      serious: "serious",
      high: "high",
      medium: "medium",
      low: "low",
      other: "other"
    }
  end

  def assessed_by=(assessed_by_option)
    if assessed_by_option == "my_team"
      self.assessed_by_team_id = current_user.team_id
    end

    super(assessed_by_option)
  end

  # Expects either a date object, or a hash containing
  # year, month and day, for example:
  #
  # {year: "2019", month: "01", day: "20"}
  def assessed_on=(assessed_on)
    super(DateParser.new(assessed_on).date)
  end

  private

  def at_least_one_product_associated
    return if product_ids.to_a.length > 0

    errors.add(:product_ids, I18n.t("product_ids.blank", scope: "activemodel.errors.models.risk_assessment_form.attributes"))
  end


  # def completed_by_is_present?
  #   return if completed_by_team_id.presence || completed_by_business_id.presence || completed_by_other.presence

  #   errors.add(:completed_by, I18n.t("completed_by.blank", scope: "activemodel.errors.models.risk_assessment_form.attributes"))
  # end

end
