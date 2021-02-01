class AccidentOrIncidentDecorator < ApplicationDecorator
  delegate_all

  def activity_cell_partial(_viewing_user)
    "activity_table_cell_with_link"
  end

  def supporting_information_title
    "#{usage}: #{product_description}"
  end

  def show_path
    h.investigation_risk_assessment_path(investigation, object)
  end

  def supporting_information_type
    type
  end

  def date_of_activity
    return unless object.date
    object.date.to_s(:govuk)
  end

  def date_added
    created_at.to_s(:govuk)
  end

  def product_description
    Product.find(object.product_id).name
  end

  def usage
    I18n.t(".accident_or_incident.usage.#{object.usage}")
  end

  def type
    byebug
    object.event_type.capitalize
  end
end
