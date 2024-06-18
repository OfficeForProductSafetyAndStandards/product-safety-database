class EmailCorrespondenceForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :correspondence_date
  attribute "correspondence_date(1i)"
  attribute "correspondence_date(2i)"
  attribute "correspondence_date(3i)"
  attribute :overview

  attribute :correspondent_name
  attribute :email_address
  attribute :email_direction

  attribute :email_subject
  attribute :details

  # These represent new file uploads
  attribute :email_file
  attribute :email_attachment

  # These are used to reference the ID of a blob that has already been saved
  # (eg if uploaded but there was a validation error)
  attribute :email_file_id
  attribute :email_attachment_id

  # These represent radio choices, to either keep the existing file, remove it or
  # replace it
  attribute :email_file_action
  attribute :email_attachment_action

  attribute :attachment_description

  # The ID of the existing email record, if it has already been saved
  attribute :id

  validates :correspondence_date,
            presence: true,
            real_date: true,
            complete_date: true,
            not_in_future: true,
            recent_date: { on_or_before: false }

  validate :date_fields_presence

  validate :validate_email_file_and_content

  validates :email_file, presence: true, if: -> { email_file_action == "replace" && email_file_id.blank? }
  validates :email_attachment, presence: true, if: -> { email_attachment_action == "replace" && email_attachment_id.blank? }

  ATTRIBUTES_FROM_EMAIL = %w[
    correspondence_date
    overview
    correspondent_name
    email_address
    email_direction
    email_subject
    details
    overview
  ].freeze

  def self.from(email)
    new(email.serializable_hash(only: ATTRIBUTES_FROM_EMAIL)).tap do |form|
      form.email_file_action = "keep"
      form.email_attachment_action = "keep"
      form.attachment_description = email.email_attachment.try(:metadata).to_h["description"]
    end
  end

  def initialize(attributes = {})
    super

    @correspondence_date_year = attributes["correspondence_date(1i)"]
    @correspondence_date_month = attributes["correspondence_date(2i)"]
    @correspondence_date_day = attributes["correspondence_date(3i)"]
  end

  def cache_files!
    if email_file.present?

      self.email_file_id = ActiveStorage::Blob.create_and_upload!(
        io: email_file,
        filename: email_file.original_filename,
        content_type: email_file.content_type
      ).signed_id
    end

    if email_attachment.present?
      self.email_attachment_id = ActiveStorage::Blob.create_and_upload!(
        io: email_attachment,
        filename: email_attachment.original_filename,
        content_type: email_attachment.content_type
      ).signed_id
    end
  end

  def cached_email_file
    return if email_file_id.nil?

    @cached_email_file ||= ActiveStorage::Blob.find_signed!(email_file_id)
  end

  def cached_email_attachment
    return if email_attachment_id.nil?

    @cached_email_attachment ||= ActiveStorage::Blob.find_signed!(email_attachment_id)
  end

private

  def set_date
    if @correspondence_date_year.present? && @correspondence_date_month.present? && @correspondence_date_day.present?
      begin
        Date.new(@correspondence_date_year.to_i, @correspondence_date_month.to_i, @correspondence_date_day.to_i)
      rescue ArgumentError
        @correspondence_date = nil
      end
    else
      @correspondence_date = nil
    end
  end

  def validate_email_file_and_content
    if email_subject_or_body_missing && email_file_removed_or_missing
      errors.add(:base, "Please provide either an email file or a subject and body")
    end
  end

  def email_file_removed_or_missing
    email_file_action == "remove" || email_file_missing
  end

  def email_subject_or_body_missing
    email_subject.blank? || details.blank?
  end

  def email_file_missing
    email_file.nil? && email_file_id.nil?
  end

  def date_fields_presence
    year = @correspondence_date_year
    month = @correspondence_date_month
    day = @correspondence_date_day

    errors.add(:correspondence_date, "Date sent must include a year") if year.blank?
    errors.add(:correspondence_date, "Date sent must include a month") if month.blank?
    errors.add(:correspondence_date, "Date sent must include a day") if day.blank?
    Date.new(year.to_i, month.to_i, day.to_i)
  rescue ArgumentError
    errors.add(:correspondence_date, "Date is invalid")
  end
end
