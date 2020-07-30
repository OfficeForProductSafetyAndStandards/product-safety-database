class RiskAssessmentDecorator < ApplicationDecorator
  delegate_all

  def risk_level_description
    if object.risk_level.present? && !object.other?
      I18n.t(".investigations.risk_level.show.levels.#{object.risk_level}")
    elsif object.custom_risk_level.present?
      object.custom_risk_level
    else
      "Not set"
    end
  end

  def supporting_information_title
    "Assessment: #{object.custom_risk_level.presence || I18n.t(".investigations.risk_level.show.levels.#{object.risk_level}")}"
  end

  def show_path
    h.investigation_risk_assessment_path(investigation, object)
  end

  def supporting_information_type
    "Risk assessment"
  end

  def date_of_activity
    object.assessed_on.to_s(:govuk)
  end

  def date_of_activity_for_sorting
    object.assessed_on
  end

  def date_added
    created_at.to_s(:govuk)
  end

  def activity_cell_partial(_viewing_user)
    "activity_table_cell_with_link"
  end
end
