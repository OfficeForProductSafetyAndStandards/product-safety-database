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

  def assign_to(investigation)
    investigation.assign_attributes(
      attributes
        .slice("hazard_description", "hazard_type", "non_compliant_reason")
        .merge(reported_reason:, description: reason_created)
    )
  end

  def self.from(investigation)
    new(reported_reason_unsafe: (investigation.unsafe? || investigation.unsafe_and_non_compliant?),
        reported_reason_non_compliant: (investigation.non_compliant? || investigation.unsafe_and_non_compliant?),
        reported_reason_safe_and_compliant: investigation.safe_and_compliant?,
        hazard_description: investigation.hazard_description,
        hazard_type: investigation.hazard_type,
        non_compliant_reason: investigation.non_compliant_reason)
  end

  def reported_reason
    return :unsafe_and_non_compliant if reported_reason_unsafe && reported_reason_non_compliant
    return :unsafe                   if reported_reason_unsafe
    return :non_compliant            if reported_reason_non_compliant
    return :safe_and_compliant       if reported_reason_safe_and_compliant
  end

private

  def reason_created
    I18n.t(reported_reason, scope: :why_reporting_form)
  end

  def mutually_exclusive_checkboxes
    return unless mutually_exclusive_checkboxes_selected?

    errors.add(:base, I18n.t(:mutually_exclusive_checkboxes_selected, scope: :why_reporting_form))
  end

  def mutually_exclusive_checkboxes_selected?
    return false unless reported_reason_safe_and_compliant

    reported_reason_safe_and_compliant && [reported_reason_unsafe, reported_reason_non_compliant].any? { |reason| reason == true }
  end

  def selected_at_least_one_checkbox
    return if at_least_one_checkbox_checked?

    errors.add(:base, I18n.t(:no_checkboxes_selected, scope: :why_reporting_form))
  end
end
