class CorrectiveAction < ApplicationRecord
  include SanitizationHelper

  MEASURE_TYPES = %w[mandatory voluntary].freeze
  DURATION_TYPES = %w[permanent temporary unknown].freeze

  belongs_to :investigation
  belongs_to :business, optional: true
  belongs_to :product

  has_many_attached :document

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

  before_validation { trim_line_endings(:other_action, :details) }
  after_create :create_audit_activity

  def action_label
    self.class.actions[action]
  end

private

  def date_decided_cannot_be_in_the_future
    if date_decided.present? && date_decided > Time.zone.today
      errors.add(:date_decided, "The date of corrective action decision can not be in the future")
    end
  end

  def create_audit_activity
    AuditActivity::CorrectiveAction::Add.from(self)
  end

end
