class PhoneCallCorrespondenceForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  validate :validate_transcript_and_content

  attribute :correspondence_date, :govuk_date
  attribute :correspondent_name
  attribute :phone_number
  attribute :overview
  attribute :details
  attribute :transcript

private

  def validate_transcript_and_content(file_blob)
    if file_blob.nil? && (overview.empty? || details.empty?)
      errors.add(:base, "Please provide either a transcript or complete the summary and notes fields")
    end
  end
end
