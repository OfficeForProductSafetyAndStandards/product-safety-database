class Correspondence::Email < Correspondence
  has_one_attached :email_file
  has_one_attached :email_attachment
  attribute :email_direction

  enum email_direction: {
    outbound: "To",
    inbound: "From"
  }

  validate :validate_email_file_and_content

  def validate_email_file_and_content
    if !email_file.attached? && (email_subject.blank? || details.blank?)
      errors.add(:base, "Please provide either an email file or a subject and body")
    end
  end
end
