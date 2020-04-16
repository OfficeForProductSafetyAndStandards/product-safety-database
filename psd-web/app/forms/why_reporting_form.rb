class WhyReportingForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :hazard_type
  attribute :hazard_description
  attribute :non_compliant_reason
  attribute :reported_reason_unsafe,             :boolean, default: false
  attribute :reported_reason_non_compliant,      :boolean, default: false
  attribute :reported_reason_safe_and_compliant, :boolean, default: false

  validate :mutually_exclusive_checkboxes

  def assign_to(investigation)
    investigation.assign_attributes(
      attributes
        .slice("hazard_description", "hazard_type", "non_compliant_reason")
        .merge(reported_reason: reported_reason, description: reason_created)
    )
  end

private

  def reported_reason
    @reported_reason ||= case [reported_reason_unsafe, reported_reason_non_compliant, reported_reason_safe_and_compliant]
                         when [true,  false, false] then Investigation.reported_reasons[:unsafe]
                         when [false, true,  false] then Investigation.reported_reasons[:non_compliant]
                         when [true,  true,  false] then Investigation.reported_reasons[:unsafe_and_non_compliant]
                         when [false, false, true]  then Investigation.reported_reasons[:safe_and_compliant]
                         end
  end

  def reason_created
    case reported_reason
    when Investigation.reported_reasons[:unsafe]                   then "Product reported because it is unsafe."
    when Investigation.reported_reasons[:non_compliant]            then "Product reported because it is non-compliant."
    when Investigation.reported_reasons[:unsafe_and_non_compliant] then "Product reported because it is unsafe and non-compliant."
    when Investigation.reported_reasons[:safe_and_compliant]       then "Product reported because it is safe and compliant."
    end
  end

  def mutually_exclusive_checkboxes
    return unless mutually_exclusive_checkboxes_selected?

    errors.add(:reported_reason_unsafe, I18n.t(:multiple_reported_reasons_selected))
    errors.add(:reported_reason_non_compliant, I18n.t(:multiple_reported_reasons_selected))      if reported_reason_non_compliant
    errors.add(:reported_reason_safe_and_compliant, I18n.t(:multiple_reported_reasons_selected)) if reported_reason_safe_and_compliant
  end

  def mutually_exclusive_checkboxes_selected?
    reported_reason_safe_and_compliant && [reported_reason_unsafe, reported_reason_non_compliant].any? { |reason| reason == true }
  end
end
