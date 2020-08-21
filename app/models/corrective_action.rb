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

  enum action: {
    ban_on_the_marketing_of_the_product_and_any_accompanying_measures: "Ban on the marketing of the product and any accompanying measures",
    destruction_of_the_product: "Destruction of the product",
    import_rejected_at_border: "Import rejected at border",
    making_the_marketing_of_the_product_subject_to_prior_conditions: "Making the marketing of the product subject to prior conditions",
    marking_the_product_with_appropriate_warnings_on_the_risks: "Marking the product with appropriate warnings on the risks",
    recall_of_the_product_from_end_users: "Recall of the product from end users",
    temporary_ban_on_the_supply_offer_to_supply_and_display_of_the_product: "Temporary ban on the supply, offer to supply and display of the product",
    warning_consumers_of_the_risks: "Warning consumers of the risks",
    withdrawal_of_the_product_from_the_market: "Withdrawal of the product from the market",
    other: "Other"
  }

  before_validation { trim_line_endings(:other_action, :details) }
  validate :date_decided_cannot_be_in_the_future
  validates :legislation, presence: { message: "Select the legislation relevant to the corrective action" }
  validates :related_file, inclusion: { in: [true, false], message: "Select whether you want to upload a related file" }
  validate :related_file_attachment_validation

  validates :measure_type, presence: true
  validates :measure_type, inclusion: { in: MEASURE_TYPES }, if: -> { measure_type.present? }
  validates :duration, presence: true
  validates :duration, inclusion: { in: DURATION_TYPES }, if: -> { duration.present? }
  validates :geographic_scope, presence: true
  validates :geographic_scope, inclusion: { in: Rails.application.config.corrective_action_constants["geographic_scope"] }, if: -> { geographic_scope.present? }
  validates :action, inclusion: { in: actions.keys }
  validates :other_action, presence: true, length: { maximum: 10_000 }, if: -> { action == "other" }

  validates :details, length: { maximum: 50_000 }

  after_create :create_audit_activity

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
