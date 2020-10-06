class Correspondence < ApplicationRecord
  include SanitizationHelper
  belongs_to :investigation, optional: true, inverse_of: :correspondences
  has_one :activity, dependent: :destroy

  before_validation :strip_whitespace
  before_validation { trim_line_endings(:details) }

  validates :email_address, allow_blank: true, format: { with: URI::MailTo::EMAIL_REGEXP }, on: :context
  validates :details, length: { maximum: 50_000 }
  validate :date_cannot_be_in_the_future

  has_many_attached :documents

  enum contact_method: {
    email: "Email",
    phone: "Phone call"
  },
       _suffix: true

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
