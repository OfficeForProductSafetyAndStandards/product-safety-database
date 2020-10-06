class PhoneCallCorrespondenceForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  validates :correspondence_date,
            presence: true,
            real_date: true,
            complete_date: true

  validate :validate_transcript_and_content

  attribute :correspondence_date, :govuk_date
  attribute :correspondent_name
  attribute :phone_number
  attribute :overview
  attribute :details
  attribute :transcript

private

  def validate_transcript_and_content
    if transcript.nil? && (overview.empty? || details.empty?)
      errors.add(:base, "Please provide either a transcript or complete the summary and notes fields")
    end
  end
end
