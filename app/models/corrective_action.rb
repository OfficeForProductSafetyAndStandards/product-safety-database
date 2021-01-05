class CorrectiveAction < ApplicationRecord
  MEASURE_TYPES = %w[mandatory voluntary].freeze
  DURATION_TYPES = %w[permanent temporary unknown].freeze

  belongs_to :investigation
  belongs_to :business, optional: true
  belongs_to :product

  has_one_attached :document

  enum has_online_recall_information: {
    has_online_recall_information_yes: :has_online_recall_information_yes,
    has_online_recall_information_no: :has_online_recall_information_no,
    has_online_recall_information_not_relevant: :has_online_recall_information_not_relevant,
  }
  enum action: {
    ban_on_the_marketing_of_the_product_and_any_accompanying_measures: I18n.t(:ban_on_the_marketing_of_the_product_and_any_accompanying_measures, scope: %i[corrective_action attributes actions]),
    destruction_of_the_product: I18n.t(:destruction_of_the_product, scope: %i[corrective_action attributes actions]),
    import_rejected_at_border: I18n.t(:import_rejected_at_border, scope: %i[corrective_action attributes actions]),
    making_the_marketing_of_the_product_subject_to_prior_conditions: I18n.t(:making_the_marketing_of_the_product_subject_to_prior_conditions, scope: %i[corrective_action attributes actions]),
    marking_the_product_with_appropriate_warnings_on_the_risks: I18n.t(:marking_the_product_with_appropriate_warnings_on_the_risks, scope: %i[corrective_action attributes actions]),
    recall_of_the_product_from_end_users: I18n.t(:recall_of_the_product_from_end_users, scope: %i[corrective_action attributes actions]),
    temporary_ban_on_the_supply_offer_to_supply_and_display_of_the_product: I18n.t(:temporary_ban_on_the_supply_offer_to_supply_and_display_of_the_product, scope: %i[corrective_action attributes actions]),
    warning_consumers_of_the_risks: I18n.t(:warning_consumers_of_the_risks, scope: %i[corrective_action attributes actions]),
    withdrawal_of_the_product_from_the_market: I18n.t(:withdrawal_of_the_product_from_the_market, scope: %i[corrective_action attributes actions]),
    other: I18n.t(:other, scope: %i[corrective_action attributes actions])
  }

  def action_label
    self.class.actions[action]
  end
end
