class CorrectiveAction < ApplicationRecord
  include DateConcern
  include SanitizationHelper

  MEASURE_TYPES = %w[mandatory voluntary].freeze
  DURATION_TYPES = %w[permanent temporary unknown].freeze

  attribute :related_file, :boolean

  belongs_to :investigation
  belongs_to :business, optional: true
  belongs_to :product

  has_many_attached :documents

  date_attribute :date_decided

  GEOGRAPHIC_SCOPES = %i[
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
      temporary_ban_on_the_supply_offer_to_supply_and_display_of_the_product:
             i18n.t(:temporary_ban_on_the_supply_offer_to_supply_and_display_of_the_product),
      warning_consumers_of_the_risks:
             i18n.t(:warning_consumers_of_the_risks),
      withdrawal_of_the_product_from_the_market:
             i18n.t(:withdrawal_of_the_product_from_the_market),
      other:
             i18n.t(:other)
    }
  end

  before_validation { trim_line_endings(:other_action, :details) }
  validate :date_decided_cannot_be_in_the_future
  validates :legislation, presence: { message: "Select the legislation relevant to the corrective action" }
  validates :related_file, inclusion: { in: [true, false], message: "Select whether you want to upload a related file" }
  validate :related_file_attachment_validation

  validates :measure_type, presence: true
  validates :measure_type, inclusion: { in: MEASURE_TYPES }, if: -> { measure_type.present? }
  validates :duration, presence: true
  validates :duration, inclusion: { in: DURATION_TYPES }, if: -> { duration.present? }
  validates :geographic_scopes, presence: true
  validates :action, inclusion: { in: actions.keys }
  validates :other_action, presence: true, length: { maximum: 10_000 }, if: :other?
  validates :other_action, absence: true, unless: :other?

  validates :details, length: { maximum: 50_000 }

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

  def related_file_attachment_validation
    if related_file && documents.attachments.empty?
      errors.add(:related_file, :file_missing, message: "Provide a related file or select no")
    end
  end
end
