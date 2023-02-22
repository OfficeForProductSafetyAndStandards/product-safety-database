class UnexpectedEventDecorator < ApplicationDecorator
  delegate_all

  def activity_cell_partial(_viewing_user)
    "activity_table_cell_with_link"
  end

  def supporting_information_title
    "#{product_description}: #{usage}"
  end

  def show_path
    h.investigation_accident_or_incident_path(investigation, object.id)
  end

  def supporting_information_type
    object.type
  end

  def event_type
    supporting_information_type
  end

  def date_of_activity
    return I18n.t(".accident_or_incident.date.unknown") unless object.date

    object.date.to_formatted_s(:govuk)
  end

  def date_added
    created_at.to_formatted_s(:govuk)
  end

  def product_description
    "#{object.investigation_product.product.name} #{object.investigation_product.psd_ref}"
  end

  def usage
    I18n.t(".accident_or_incident.usage.#{object.usage}")
  end

  def page_title
    "#{object.type.capitalize} involving #{product_description}"
  end

  def severity
    return object.severity_other if severity_other.present?

    I18n.t(".accident_or_incident.severity.#{object.severity}")
  end

  def is_attached_to_versioned_product?
    !!investigation_closed_at
  end

  def investigation_closed_at
    object.investigation_product.investigation_closed_at
  end

  def psd_ref
    object.investigation_product.psd_ref
  end
end
