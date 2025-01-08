class EditWhyReportingForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :hazard_type
  attribute :hazard_description
  attribute :non_compliant_reason
  attribute :reported_reason_unsafe,             :boolean, default: false
  attribute :reported_reason_non_compliant,      :boolean, default: false
  attribute :reported_reason

  validates :reported_reason, presence: true
  validates :hazard_type, :hazard_description, presence: true, if: -> { reported_reason == "unsafe" || reported_reason == "unsafe_and_non_compliant" }
  validates :non_compliant_reason, presence: true, if: -> { reported_reason == "non_compliant" || reported_reason == "unsafe_and_non_compliant" }

  def assign_to(investigation)
    investigation.assign_attributes(
      attributes
        .slice("hazard_description", "hazard_type", "non_compliant_reason")
        .merge(reported_reason:, description: reason_created)
    )
  end

  def self.from(investigation, reported_reason)
    attributes = { reported_reason: }

    if %w[unsafe unsafe_and_non_compliant].include?(reported_reason)
      attributes[:hazard_description] = investigation.hazard_description
      attributes[:hazard_type] = investigation.hazard_type
    end

    if %w[non_compliant unsafe_and_non_compliant].include?(reported_reason)
      attributes[:non_compliant_reason] = investigation.non_compliant_reason
    end

    new(**attributes)
  end

  def reported_reason_unsafe
    reported_reason == "unsafe" || reported_reason == "unsafe_and_non_compliant"
  end

  def reported_reason_non_compliant
    reported_reason == "non_compliant" || reported_reason == "unsafe_and_non_compliant"
  end

private

  def reason_created
    I18n.t(reported_reason, scope: :why_reporting_form)
  end
end
