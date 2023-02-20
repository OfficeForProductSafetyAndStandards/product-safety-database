class CorrectiveActionDecorator < ApplicationDecorator
  delegate_all
  include SupportingInformationHelper

  MEDIUM_TITLE_TEXT_SIZE_THRESHOLD = 62

  def geographic_scopes
    object.geographic_scopes.map { |geographic_scope|
      I18n.t(geographic_scope, scope: %i[corrective_action attributes geographic_scopes])
    }.to_sentence
  end

  def details
    return if object.details.blank?

    h.simple_format(object.details)
  end

  def page_title
    other? ? other_action : CorrectiveAction.actions[action]
  end

  def supporting_information_title
    action_name = other? ? other_action : I18n.t(action, scope: %i[corrective_action attributes actions])

    "#{action_name}: #{investigation_product.product.name}"
  end

  def date_of_activity
    date_decided.to_formatted_s(:govuk)
  end

  def date_of_activity_for_sorting
    date_decided
  end

  def date_added
    created_at.to_formatted_s(:govuk)
  end

  def show_path
    h.investigation_corrective_action_path(investigation, object)
  end

  def measure_type
    object.measure_type&.upcase_first
  end

  def duration
    object.duration.upcase_first
  end

  def display_medium_title_text_size?
    page_title.length > MEDIUM_TITLE_TEXT_SIZE_THRESHOLD
  end
end
