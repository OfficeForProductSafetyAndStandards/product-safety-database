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
    "#{risk_level_description}: #{products_description}"
  end

  def supporting_information_full_title
    "#{risk_level_description}: #{products_with_brand_description}"
  end

  def show_path
    h.investigation_risk_assessment_path(investigation, object)
  end

  def supporting_information_type
    "Other risk assessment"
  end

  def date_of_activity
    object.assessed_on.to_formatted_s(:govuk)
  end

  def date_of_activity_for_sorting
    object.assessed_on
  end

  def date_added
    created_at.to_formatted_s(:govuk)
  end

  def activity_cell_partial(_viewing_user)
    "activity_table_cell_with_link"
  end

  def assessed_by
    return assessed_by_business.legal_name if assessed_by_business_id
    return assessed_by_team.name if assessed_by_team_id

    assessed_by_other
  end

  def product_titles
    values = object.investigation_products.map do |ip|
      "#{ip.product.name} (#{ip.psd_ref})"
    end
    h.safe_join(values, h.tag.br)
  end

  def case_id
    object.investigation.pretty_id
  end

private

  def products_description
    products = object.investigation_products.map(&:product)

    if products.size > 1
      h.pluralize(products.size, "product")
    else
      products.first.name
    end
  end

  def products_with_brand_description
    products = object.investigation_products.map(&:product)

    if products.size > 1
      h.pluralize(products.size, "product")
    else
      products.first.decorate.name_with_brand
    end
  end
end
