class PrismRiskAssessmentDecorator < ApplicationDecorator
  delegate_all

  def risk_level_description
    if object.overall_product_risk_level.present?
      I18n.t(".investigations.risk_level.show.levels.#{object.overall_product_risk_level}")
    else
      "Not set"
    end
  end

  def supporting_information_title
    name
  end

  def show_path
    Prism::Engine.routes.url_helpers.view_submitted_assessment_risk_assessment_tasks_path(object)
  end

  def supporting_information_type
    "PRISM risk assessment"
  end

  def date_of_activity
    object.updated_at.to_formatted_s(:govuk)
  end

  def date_of_activity_for_sorting
    object.updated_at
  end

  def date_added
    created_at.to_formatted_s(:govuk)
  end

  def activity_cell_partial(_viewing_user)
    "activity_table_cell_with_link"
  end

  def assessed_by
    User.find(created_by_user_id)&.name
  end

  def product_titles
    product_name
  end

  def case_id
    ""
  end
end
