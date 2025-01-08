# Recording of meeting correspondence is deprecated - existing data is still supported
class AuditActivity::Correspondence::AddMeeting < AuditActivity::Correspondence::Base
  belongs_to :correspondence, class_name: "Correspondence::Meeting"
  include ActivityAttachable
  with_attachments transcript: "transcript", related_attachment: "related attachment"

  def readonly?
    true
  end

  def activity_type
    "meeting"
  end

  def restricted_title(_user)
    "Meeting added"
  end

private

  def subtitle_slug
    "Meeting recorded"
  end
end
