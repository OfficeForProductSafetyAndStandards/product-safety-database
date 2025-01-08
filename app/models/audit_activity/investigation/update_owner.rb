class AuditActivity::Investigation::UpdateOwner < AuditActivity::Investigation::Base
  def self.build_metadata(owner, rationale)
    {
      owner_id: owner.id,
      rationale:
    }
  end

  def title(user)
    "Notification owner changed to #{owner.decorate.display_name(viewer: user)}"
  end

  def body
    metadata["rationale"]
  end

  def owner
    User.find_by(id: metadata["owner_id"]) || Team.find_by(id: metadata["owner_id"])
  end

private

  def subtitle_slug
    "Changed"
  end
end
