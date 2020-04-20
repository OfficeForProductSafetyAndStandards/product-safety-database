class WhyReportingForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :hazard_type
  attribute :hazard_description
  attribute :non_compliant_reason
  attribute :reported_reason_unsafe,             :boolean, default: false
  attribute :reported_reason_non_compliant,      :boolean, default: false
  attribute :reported_reason_safe_and_compliant, :boolean, default: false

  validate :selected_at_least_one_checkbox
  validate :mutually_exclusive_checkboxes
  validates :non_compliant_reason, presence: true, if: -> { reported_reason_non_compliant }

  def assign_to(investigation)
    investigation.assign_attributes(
      attributes
        .slice("hazard_description", "hazard_type", "non_compliant_reason")
        .merge(reported_reason: reported_reason, description: reason_created)
    )
  end

private

  def reported_reason
    @reported_reason ||= case checkboxes
                         when [true,  false, false] then Investigation.reported_reasons[:unsafe]
                         when [false, true,  false] then Investigation.reported_reasons[:non_compliant]
                         when [true,  true,  false] then Investigation.reported_reasons[:unsafe_and_non_compliant]
                         when [false, false, true]  then Investigation.reported_reasons[:safe_and_compliant]
                         end
  end

  def reason_created
    I18n.t(reported_reason, scope: :why_reporting_form)
  end

  def mutually_exclusive_checkboxes
    return unless mutually_exclusive_checkboxes_selected?

    errors.add(:reported_reason_unsafe,
               I18n.t(:mutually_exclusive_checkboxes_selected, scope: :why_reporting_form))
    if reported_reason_non_compliant
      errors.add(:reported_reason_non_compliant,
                 I18n.t(:mutually_exclusive_checkboxes_selected, scope: :why_reporting_form))
    end
    if reported_reason_safe_and_compliant
      errors.add(:reported_reason_safe_and_compliant,
                 I18n.t(:mutually_exclusive_checkboxes_selected, scope: :why_reporting_form))
    end
  end

  def mutually_exclusive_checkboxes_selected?
    return false unless reported_reason_safe_and_compliant

    reported_reason_safe_and_compliant && [reported_reason_unsafe, reported_reason_non_compliant].any? { |reason| reason == true }
  end

  def selected_at_least_one_checkbox
    return if at_least_one_checkbox_checked?

    errors.add(:reported_reason_unsafe,
               I18n.t(:no_checkboxes_selected, scope: :why_reporting_form))
    errors.add(:reported_reason_non_compliant,
               I18n.t(:no_checkboxes_selected, scope: :why_reporting_form))
    errors.add(:reported_reason_safe_and_compliant,
               I18n.t(:no_checkboxes_selected, scope: :why_reporting_form))
  end

  def at_least_one_checkbox_checked?
    checkboxes.any? { |checkbox| checkbox == true }
  end

  def checkboxes
    @checkboxes ||= [reported_reason_unsafe, reported_reason_non_compliant, reported_reason_safe_and_compliant]
  end
end
