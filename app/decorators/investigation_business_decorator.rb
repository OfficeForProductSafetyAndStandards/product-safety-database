class InvestigationBusinessDecorator < ApplicationDecorator
  delegate_all

  def pretty_relationship
    I18n.t(".business.type.#{relationship}", default: relationship.capitalize).humanize
  end
end
