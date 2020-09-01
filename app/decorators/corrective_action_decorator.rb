class CorrectiveActionDecorator < ApplicationDecorator
  TRUNCATED_ACTION_MAP = {
    ban_on_the_marketing_of_the_product_and_any_accompanying_measures: "Ban on marketing",
    destruction_of_the_product: "Destruction of product",
    import_rejected_at_border: "Import rejected",
    making_the_marketing_of_the_product_subject_to_prior_conditions: "Marketing conditions",
    marking_the_product_with_appropriate_warnings_on_the_risks: "Add risk warning to product",
    recall_of_the_product_from_end_users: "Recall",
    temporary_ban_on_the_supply_offer_to_supply_and_display_of_the_product: "Temporary ban",
    warning_consumers_of_the_risks: "Warn consumers of risks",
    withdrawal_of_the_product_from_the_market: "Withdrawal"
  }.freeze

  delegate_all
  include SupportingInformationHelper

  MEDIUM_TITLE_TEXT_SIZE_THRESHOLD = 62

  def details
    return if object.details.blank?

    h.simple_format(object.details)
  end

  def supporting_information_title
    action_name = other? ? other_action : TRUNCATED_ACTION_MAP[action.to_sym]

    "#{action_name}: #{product.name}"
  end

  def date_of_activity
    date_decided.to_s(:govuk)
  end

  def date_of_activity_for_sorting
    date_decided
  end

  def date_added
    created_at.to_s(:govuk)
  end

  def show_path
    h.investigation_action_path(investigation, object)
  end

  def measure_type
    object.measure_type&.upcase_first
  end

  def duration
    object.duration.upcase_first
  end

  def file_attached?
    documents.any?
  end

  def display_medium_title_text_size?
    supporting_information_title.length > MEDIUM_TITLE_TEXT_SIZE_THRESHOLD
  end
end
