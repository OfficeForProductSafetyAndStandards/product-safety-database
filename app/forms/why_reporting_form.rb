class WhyReportingForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :hazard_type
  attribute :hazard_description
  attribute :non_compliant_reason
  attribute :reported_reason_unsafe,             :boolean, default: false
  attribute :reported_reason_non_compliant,      :boolean, default: false
  attribute :reported_reason_safe_and_compliant, :boolean, default: false
  attribute :reported_reason

  validates :non_compliant_reason, presence: true, if: -> { (reported_reason == "non_compliant" || reported_reason == "unsafe_and_non_compliant") }
  validates :hazard_description, :hazard_type, presence: true, if: -> { (reported_reason == "unsafe" || reported_reason == "unsafe_and_non_compliant") }

  def assign_to(investigation)
    investigation.assign_attributes(
      attributes
        .slice("hazard_description", "hazard_type", "non_compliant_reason")
    )
  end

  def self.from(investigation, reported_reason)
    attributes = { reported_reason: reported_reason }
    
    if (reported_reason == "unsafe" || reported_reason == "unsafe_and_non_compliant")
      attributes.merge!({ hazard_description: investigation.hazard_description, hazard_type: investigation.hazard_type })
    end

    if (reported_reason == "unsafe" || reported_reason == "unsafe_and_non_compliant")
      attributes.merge!({ non_compliant_reason: investigation.non_compliant_reason })
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
