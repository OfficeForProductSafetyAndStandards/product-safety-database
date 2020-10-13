class EmailCorrespondenceForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :correspondence_date, :govuk_date
  attribute :overview

  attribute :correspondent_name
  attribute :email_address
  attribute :email_direction

  attribute :email_subject
  attribute :details

  attribute :email_file
  attribute :email_attachment
  attribute :attachment_description

  # These reference the signed IDs of Blobs that have already
  # been uploaded, submitted via hidden fields
  attribute :existing_email_file_id
  attribute :existing_email_attachment_id

  validates :correspondence_date,
            presence: true,
            real_date: true,
            complete_date: true,
            in_future: true

  validate :validate_email_file_and_content

private

  def validate_email_file_and_content
    if email_file.nil? && existing_email_file_id.blank? && (email_subject.blank? || details.blank?)
      errors.add(:base, "Please provide either an email file or a subject and body")
    end
  end
end
