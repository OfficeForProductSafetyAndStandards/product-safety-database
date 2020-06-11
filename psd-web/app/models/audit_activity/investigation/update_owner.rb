class AuditActivity::Investigation::UpdateOwner < AuditActivity::Investigation::Base
  def self.from(*)
    raise "Deprecated - use ChangeCaseOwner.call instead"
  end

  def self.build_metadata(owner, rationale)
    {
      owner_id: owner.id,
      rationale: rationale
    }
  end

  def title(user)
    "Case owner changed to #{owner.decorate.display_name(viewer: user)}"
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

  # Do not send investigation_updated mail. This is handled by the ChangeCaseOwner service
  def notify_relevant_users; end
end
