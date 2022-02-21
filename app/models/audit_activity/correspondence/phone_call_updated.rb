class AuditActivity::Correspondence::PhoneCallUpdated < AuditActivity::Correspondence::Base
  belongs_to :correspondence, class_name: "Correspondence::PhoneCall"

  def self.build_metadata(correspondence)
    updates = correspondence.previous_changes

    if correspondence.attachment_changes.any?
      updates["transcript"] = correspondence.attachment_changes["transcript"].blob.filename
    end

    { updates: }
  end

  def restricted_title(_user)
    "Phone call updated"
  end

private

  def subtitle_slug
    "Phone call updated"
  end
end
