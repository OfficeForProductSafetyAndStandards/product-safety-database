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

  attribute :email_file_action
  attribute :email_attachment_action

  # These reference the signed IDs of Blobs that have already
  # been uploaded, submitted via hidden fields
  attribute :existing_email_file_id
  attribute :existing_email_attachment_id

  validates :correspondence_date,
            presence: true,
            real_date: true,
            complete_date: true

  validate :validate_email_file_and_content

  validate :correspondence_date_cannot_be_in_future

  def validate_email_file_and_content
    if email_file.nil? && existing_email_file_id.blank? && (email_subject.blank? || details.blank?)
      errors.add(:base, "Please provide either an email file or a subject and body")
    end
  end

  def correspondence_date_cannot_be_in_future
    if correspondence_date.is_a?(Date) && correspondence_date > Time.zone.today

      errors.add(:correspondence_date, :in_future)
    end
  end
end
