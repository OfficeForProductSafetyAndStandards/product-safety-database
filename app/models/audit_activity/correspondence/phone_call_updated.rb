class AuditActivity::Correspondence::PhoneCallUpdated < AuditActivity::Correspondence::Base
  belongs_to :correspondence, class_name: "Correspondence::PhoneCall"

  def self.from(*)
    raise "Deprecated - no longer supported"
  end

  def title(_viewing_user = nil)
    correspondence.overview
  end

  def self.build_metadata(correspondence)
    updates = correspondence.previous_changes

    if correspondence.attachment_changes.any?
      updates["transcript"] = correspondence.attachment_changes["transcript"].blob.filename
    end

    { updates: updates }
  end

  def restricted_title(_user)
    "Phone call updated"
  end

private

  def subtitle_slug
    "Phone call updated"
  end

  # no-op sending of email is done by the service UpdatePhoneCall
  def notify_relevant_users; end
end
