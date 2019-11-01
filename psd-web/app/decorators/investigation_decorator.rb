class InvestigationDecorator < ApplicationDecorator
  delegate_all

  def title
    user_title
  end
end
