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
  validates :other_details, length: { maximum: 10_000 }

  redacted_export_with :id, :complainant_type, :created_at, :investigation_id, :updated_at

  def has_contact_details?
    email_address.present? || name.present? || other_details.present? || phone_number.present?
  end
end
