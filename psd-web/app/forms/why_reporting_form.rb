class WhyReportingForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :hazard_type
  attribute :hazard_description
  attribute :non_compliant_reason
  attribute :reported_reason_unsafe, :boolean, default: false
  attribute :reported_reason_non_compliant, :boolean, default: false
  attribute :reported_reason_safe_and_compliant, :boolean, default: false

  validate :single_option_selected

  def reported_reason
    @reported_reason ||= case boolean_checkboxes
                         when [true, false, false] then :unsafe
                         when [false, true, false] then :non_compliant
                         when [false, false, true] then :safe_and_compliant
                         end
  end

private

  def single_option_selected
    return unless multiple_reported_reasons_selected?

    errors.add(:reported_reason_unsafe, I18n.t(:multiple_reported_reasons_selected))             if reported_reason_unsafe
    errors.add(:reported_reason_non_compliant, I18n.t(:multiple_reported_reasons_selected))      if reported_reason_non_compliant
    errors.add(:reported_reason_safe_and_compliant, I18n.t(:multiple_reported_reasons_selected)) if reported_reason_safe_and_compliant
  end

  def multiple_reported_reasons_selected?
    boolean_checkboxes.many? { |reason| reason == true }
  end

  def boolean_checkboxes
    [reported_reason_unsafe, reported_reason_non_compliant, reported_reason_safe_and_compliant]
  end
end
