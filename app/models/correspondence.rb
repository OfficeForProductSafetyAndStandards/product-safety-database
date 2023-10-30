class Correspondence < ApplicationRecord
  include SanitizationHelper
  belongs_to :investigation, optional: true, inverse_of: :correspondences
  has_many :activities, dependent: :destroy

  before_validation :strip_whitespace
  before_validation { trim_line_endings(:details) }

  validates :email_address, allow_blank: true, format: { with: URI::MailTo::EMAIL_REGEXP }, on: :context
  validates :details, length: { maximum: 32_767 }
  validate :date_cannot_be_in_the_future

  has_many_attached :documents

  enum contact_method: {
         email: "Email",
         phone: "Phone call"
       },
       _suffix: true

  redacted_export_with :id, :contact_method, :correspondence_date, :correspondent_type,
                       :created_at, :email_direction, :investigation_id, :type, :updated_at

  def strip_whitespace
    changed.each do |attribute|
      if send(attribute).respond_to?(:strip)
        send("#{attribute}=", send(attribute).strip)
      end
    end
  end

  def date_cannot_be_in_the_future
    if correspondence_date.present? && correspondence_date > Time.zone.today
      errors.add(:correspondence_date, "Correspondence date must be today or in the past")
    end
  end
end
