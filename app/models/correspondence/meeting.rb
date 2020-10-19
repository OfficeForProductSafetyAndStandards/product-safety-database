class Correspondence::Meeting < Correspondence
  include DateConcern
  has_one_attached :transcript
  has_one_attached :related_attachment

  date_attribute :correspondence_date

  def validate_transcript_and_content(file_blob)
    if file_blob.nil? && (overview.empty? || details.empty?)
      errors.add(:base, "Please provide either a transcript or complete the summary and notes fields")
    end
  end
end
