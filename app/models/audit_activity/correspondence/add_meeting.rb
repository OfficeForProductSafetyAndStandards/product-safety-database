# Recording of meeting correspondence is deprecated - existing data is still supported
class AuditActivity::Correspondence::AddMeeting < AuditActivity::Correspondence::Base
  belongs_to :correspondence, class_name: "Correspondence::Meeting"
  include ActivityAttachable
  with_attachments transcript: "transcript", related_attachment: "related attachment"

  def self.from(*)
    raise "Deprecated - no longer supported"
  end

  def activity_type
    "meeting"
  end

  def restricted_title(_user)
    "Meeting added"
  end

  def email_update_text(viewer = nil)
    "Meeting details added to the #{investigation.case_type.upcase_first} by #{source&.show(viewer)}."
  end

private

  def subtitle_slug
    "Meeting recorded"
  end
end
