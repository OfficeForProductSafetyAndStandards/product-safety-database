class Complainant < ApplicationRecord
  include SanitizationHelper

  TYPES = {
    "Consumer": "A consumer",
    "Business": "A business",
    "Local authority (Trading Standards)": "Local authority (Trading Standards)",
    "Other government department": "Other government department",
    "Emergency service": "Emergency service",
    "Internal": "Internal"
  }.freeze

  belongs_to :investigation, optional: true

  before_validation { trim_line_endings(:name, :other_details) }
  validates :complainant_type, presence: { message: "Select complainant type" }
  validates :investigation, presence: true, on: %i[create update]
  validates :email_address, allow_blank: true, format: { with: URI::MailTo::EMAIL_REGEXP }, on: :complainant_details

  validates :name, length: { maximum: 100 }
  validates :other_details, length: { maximum: 10000 }

  def can_be_displayed?
    can_be_seen_by_current_user? || investigation.child_should_be_displayed?
  end

private

  def can_be_seen_by_current_user?
    return true if investigation.source&.user_has_gdpr_access?

    complainant_type != "Consumer"
  end
end
