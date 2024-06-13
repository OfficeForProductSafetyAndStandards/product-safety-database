class PhoneCallCorrespondenceForm
  include ActiveModel::Model
  include ActiveModel::Attributes


  validates :correspondence_date,
            presence: true,
            real_date: true,
            complete_date: true,
            not_in_future: true,
            recent_date: { on_or_before: false }

  validate :validate_transcript_and_content

  attribute :correspondence_date
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

  def initialize(*args)
    super

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

  def validate_transcript_and_content
    if transcript.nil? & (overview.blank? || details.blank?)
      errors.add(:base, "Please provide either a transcript or complete the summary and notes fields")
    end
  end

  def strip_line_feed_from_textarea
    details&.strip!
  end
end
