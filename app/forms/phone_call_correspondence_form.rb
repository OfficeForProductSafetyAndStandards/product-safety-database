class PhoneCallCorrespondenceForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  validates :correspondence_date,
            presence: true,
            real_date: true,
            complete_date: true,
            in_future: true

  validate :validate_transcript_and_content

  attribute :correspondence_date, :govuk_date
  attribute :correspondent_name
  attribute :phone_number
  attribute :overview
  attribute :details
  attribute :transcript
  attribute :existing_transcript_file_id

  def cache_file!
    return if transcript.blank?

    blob = ActiveStorage::Blob.create_after_upload!(
      io: transcript,
      filename: transcript.original_filename,
      content_type: transcript.content_type
    )

    self.existing_transcript_file_id = blob.signed_id
  end

  def load_transcript_file
    if existing_transcript_file_id.present? && transcript.nil?
      self.transcript = ActiveStorage::Blob.find_signed(existing_transcript_file_id)
    end
  end

private

  def validate_transcript_and_content
    if transcript.nil? & (overview.blank? || details.blank?)
      errors.add(:base, "Please provide either a transcript or complete the summary and notes fields")
    end
  end
end
