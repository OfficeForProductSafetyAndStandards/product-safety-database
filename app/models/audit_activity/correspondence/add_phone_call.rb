class AuditActivity::Correspondence::AddPhoneCall < AuditActivity::Correspondence::Base
  include ActivityAttachable
  with_attachments transcript: "transcript"
  belongs_to :correspondence, class_name: "Correspondence::PhoneCall"

  def title(_viewing_user)
    correspondence.overview
  end

  def self.build_metadata
    {}
  end

  def restricted_title(_user)
    "Phone call added"
  end

  def email_update_text(viewer = nil)
    "Phone call details added to the #{investigation.case_type.upcase_first} by #{source&.show(viewer)}."
  end

private

  def subtitle_slug
    "Phone call"
  end
end
