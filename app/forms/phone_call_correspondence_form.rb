class PhoneCallCorrespondenceForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  validates :correspondence_date,
            presence: true,
            real_date: true,
            complete_date: true,
            not_in_future: true,
            recent_date: { on_or_before: false }

  validate :date_fields_presence
  validate :validate_transcript_and_content

  attr_accessor :correspondence_date_year, :correspondence_date_month, :correspondence_date_day

  attribute :correspondence_date
  attribute "correspondence_date(1i)"
  attribute "correspondence_date(2i)"
  attribute "correspondence_date(3i)"
  attribute :correspondent_name
  attribute :phone_number
  attribute :overview
  attribute :details
  attribute :transcript
  attribute :existing_transcript_file_id
  attribute :id

  ATTRIBUTES_FROM_PHONE_CALL = %w[
    correspondence_date
    correspondent_name
    details
    id
    phone_number
    overview
  ].freeze

  def self.from(phone_call)
    new(phone_call.serializable_hash(only: ATTRIBUTES_FROM_PHONE_CALL, methods: :transcript)).tap do |form|
      form.existing_transcript_file_id = phone_call.transcript.signed_id if phone_call.transcript.attached?
    end
  end

  def initialize(attributes = {})
    super

    @correspondence_date_year = attributes["correspondence_date(1i)"]
    @correspondence_date_month = attributes["correspondence_date(2i)"]
    @correspondence_date_day = attributes["correspondence_date(3i)"]
    strip_line_feed_from_textarea
  end

  def cache_file!
    return if transcript.blank?

    self.transcript = ActiveStorage::Blob.create_and_upload!(
      io: transcript,
      filename: transcript.original_filename,
      content_type: transcript.content_type
    )

    self.existing_transcript_file_id = transcript.signed_id
  end

  def load_transcript_file
    if existing_transcript_file_id.present? && transcript.nil?
      self.transcript = ActiveStorage::Blob.find_signed!(existing_transcript_file_id)
    end
  end

  def persisted?
    id.present?
  end

private

  def set_date
    if @correspondence_date_year.present? && @correspondence_date_month.present? && @correspondence_date_day.present?
      begin
        self.correspondence_date = Date.new(@correspondence_date_year.to_i, @correspondence_date_month.to_i, @correspondence_date_day.to_i)
      rescue ArgumentError
        self.correspondence_date = { day: @correspondence_date_day, month: @correspondence_date_month, year: @correspondence_date_year }
      end
    else
      self.correspondence_date = { day: @correspondence_date_day, month: @correspondence_date_month, year: @correspondence_date_year }
    end
  end

  def validate_transcript_and_content
    if transcript.nil? & (overview.blank? || details.blank?)
      errors.add(:overview, "Please provide either a transcript or complete the summary and notes fields")
    end
  end

  def strip_line_feed_from_textarea
    details&.strip!
  end

  def date_fields_presence
    year = @correspondence_date_year
    month = @correspondence_date_month
    day = @correspondence_date_day

    errors.add(:correspondence_date, "Enter the date of call") if year.blank? && month.blank? && day.blank?
  rescue ArgumentError
    errors.add(:correspondence_date, "Date is invalid")
  end
end
