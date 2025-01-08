class CorrectiveAction < ApplicationRecord
  self.ignored_columns = %w[product_id]

  MEASURE_TYPES = %w[mandatory voluntary].freeze
  DURATION_TYPES = %w[permanent temporary unknown].freeze
  TRUNCATED_ACTION_MAP = {
    ban_on_the_marketing_of_the_product_and_any_accompanying_measures: "Ban on marketing",
    destruction_of_the_product: "Destruction of product",
    import_rejected_at_border: "Import rejected",
    making_the_marketing_of_the_product_subject_to_prior_conditions: "Marketing conditions",
    marking_the_product_with_appropriate_warnings_on_the_risks: "Add risk warning to product",
    recall_of_the_product_from_end_users: "Recall",
    removal_of_the_listing_by_the_online_marketplace: "Removal from online marketplace",
    temporary_ban_on_the_supply_offer_to_supply_and_display_of_the_product: "Temporary ban",
    warning_consumers_of_the_risks: "Warn consumers of risks",
    withdrawal_of_the_product_from_the_market: "Withdrawal",
    product_back_into_compliance: "Product back into compliance",
    seizure_of_goods: "Seizure of goods",
    modification_programme: "Modification programme",
    referred_to_overseas_regulator: "Referred to overseas regulator",
    product_no_longer_available_for_sale: "Product no longer available for sale"
  }.freeze

  belongs_to :investigation
  belongs_to :business, optional: true
  belongs_to :investigation_product

  has_one_attached :document

  enum has_online_recall_information: {
    "has_online_recall_information_yes" => "has_online_recall_information_yes",
    "has_online_recall_information_no" => "has_online_recall_information_no",
    "has_online_recall_information_not_relevant" => "has_online_recall_information_not_relevant"
  }

  GEOGRAPHIC_SCOPES = %w[
    local
    great_britain
    northern_ireland
    eea_wide
    eu_wide
    worldwide
    unknown
  ].freeze

  I18n.with_options scope: %i[corrective_action attributes actions] do |i18n|
    enum action: {
      ban_on_the_marketing_of_the_product_and_any_accompanying_measures:
        i18n.t(:ban_on_the_marketing_of_the_product_and_any_accompanying_measures),
      destruction_of_the_product:
        i18n.t(:destruction_of_the_product),
      import_rejected_at_border:
        i18n.t(:import_rejected_at_border),
      making_the_marketing_of_the_product_subject_to_prior_conditions:
        i18n.t(:making_the_marketing_of_the_product_subject_to_prior_conditions),
      marking_the_product_with_appropriate_warnings_on_the_risks:
        i18n.t(:marking_the_product_with_appropriate_warnings_on_the_risks),
      recall_of_the_product_from_end_users:
        i18n.t(:recall_of_the_product_from_end_users, scope: %i[corrective_action attributes actions]),
      removal_of_the_listing_by_the_online_marketplace:
        i18n.t(:removal_of_the_listing_by_the_online_marketplace, scope: %i[corrective_action attributes actions]),
      temporary_ban_on_the_supply_offer_to_supply_and_display_of_the_product:
        i18n.t(:temporary_ban_on_the_supply_offer_to_supply_and_display_of_the_product),
      warning_consumers_of_the_risks:
        i18n.t(:warning_consumers_of_the_risks),
      withdrawal_of_the_product_from_the_market:
        i18n.t(:withdrawal_of_the_product_from_the_market),
      product_back_into_compliance:
        i18n.t(:product_back_into_compliance),
      seizure_of_goods:
        i18n.t(:seizure_of_goods),
      modification_programme:
        i18n.t(:modification_programme),
      referred_to_overseas_regulator:
        i18n.t(:referred_to_overseas_regulator),
      product_no_longer_available_for_sale:
        i18n.t(:product_no_longer_available_for_sale),
      other:
        i18n.t(:other)
    }
  end

  GEOGRAPHIC_SCOPES_MIGRATION_MAP = {
    "Local" => %w[local],
    "Regional" => %w[great_britain northern_ireland],
    "National" => %w[great_britain northern_ireland],
    "EEA wide" => %w[eea_wide],
    "EU wide" => %w[eu_wide],
    "Unknown" => %w[unknown],
    nil => %w[unknown]
  }.freeze

  redacted_export_with :id, :action, :business_id, :created_at, :date_decided, :details, :duration,
                       :geographic_scope, :geographic_scopes, :has_online_recall_information,
                       :investigation_id, :investigation_product_id, :legislation, :measure_type,
                       :online_recall_information, :other_action, :updated_at

  def self.migrate_geographical_scope(corrective_action)
    corrective_action.update!(geographic_scopes: GEOGRAPHIC_SCOPES_MIGRATION_MAP[corrective_action.geographic_scope])
  end

  def action_label
    self.class.actions[action]
  end
end
