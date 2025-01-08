class AuditActivity::Correspondence::AddPhoneCall < AuditActivity::Correspondence::Base
  include ActivityAttachable
  with_attachments transcript: "transcript"
  belongs_to :correspondence, class_name: "Correspondence::PhoneCall"

  def self.build_metadata(correspondence)
    { "correspondence" => correspondence.attributes.merge(
      "transcript" => correspondence.transcript.blob&.attributes
    ) }
  end

  def title(*)
    metadata["correspondence"]["overview"]
  end

  def correspondent_name
    metadata["correspondence"]["correspondent_name"]
  end

  def correspondence_date
    return if metadata["correspondence"]["correspondence_date"].nil?

    Date.parse(metadata["correspondence"]["correspondence_date"])
  end

  def phone_number
    metadata["correspondence"]["phone_number"]
  end

  def filename
    metadata["correspondence"]["transcript"]&.fetch("filename")
  end

  def details
    metadata["correspondence"]["details"]
  end

  def restricted_title(_user)
    "Phone call added"
  end

private

  def subtitle_slug
    "Phone call"
  end
end
