class WhyReportingForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :hazard_type
  attribute :hazard_description
  attribute :non_compliant_reason
  attribute :reported_reason_unsafe, :boolean, default: false
  attribute :reported_reason_non_compliant, :boolean, default: false
  attribute :reported_reason_safe_and_compliant, :boolean, default: false

  validate :mutually_exclusive_checkboxes

  def reported_reason
    @reported_reason ||= case boolean_checkboxes
                         when [true,  false, false] then :unsafe
                         when [false, true,  false] then :non_compliant
                         when [false, false, true]  then :safe_and_compliant
                         end
  end

  def assign_to(investigation)
    investigation.assign_attributes(
      attributes
        .slice(:hazard_description, :hazard_type, :non_compliant_reason)
        .merge(reported_reason: reported_reason)
    )
  end

private

  def mutually_exclusive_checkboxes
    return unless mutually_exclusive_checkboxes_selected?

    errors.add(:reported_reason_unsafe, I18n.t(:multiple_reported_reasons_selected))
    errors.add(:reported_reason_non_compliant, I18n.t(:multiple_reported_reasons_selected))      if reported_reason_non_compliant
    errors.add(:reported_reason_safe_and_compliant, I18n.t(:multiple_reported_reasons_selected)) if reported_reason_safe_and_compliant
  end

  def mutually_exclusive_checkboxes_selected?
    reported_reason_safe_and_compliant && [reported_reason_unsafe, reported_reason_non_compliant].any? { |reason| reason == true }
  end

  def boolean_checkboxes
    [reported_reason_unsafe, reported_reason_non_compliant, reported_reason_safe_and_compliant]
  end
end
