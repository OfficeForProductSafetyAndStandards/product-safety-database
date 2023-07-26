class InvestigationBusinessDecorator < ApplicationDecorator
  delegate_all

  def pretty_relationship
    return authorised_representative_relationship if relationship == "authorised_representative"

    business_type_relationship
  end

private

  def business_type_relationship
    I18n.t("business.type.#{relationship}", default: relationship.capitalize)
  end

  def authorised_representative_relationship
    I18n.t("business.type.authorised_reprsentative.#{authorised_representative_choice}", default: authorised_representative_choice.capitalize)
  end
end
