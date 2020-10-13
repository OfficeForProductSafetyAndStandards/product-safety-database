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

private

  def subtitle_slug
    "Phone call"
  end

  # no-op sending of email is done by the service AddPhoneCallToCase
  def notify_relevant_users; end
end
