class AuditActivity::Investigation::AutomaticallyUpdateOwner < AuditActivity::Investigation::Base
  def self.from(*)
    raise "Deprecated - use DeleteUser.call instead"
  end

  def self.build_metadata(owner)
    {
      owner_id: owner.id
    }
  end

  def title(user)
    type = investigation.case_type.capitalize
    new_owner = owner.decorate.display_name(viewer: user)
    "Case owner automatically changed on #{type} to #{new_owner}"
  end

  def subtitle(_viewer)
    "Case owner automatically changed, #{pretty_date_stamp}"
  end

private

  def owner
    User.find_by(id: metadata["owner_id"]) || Team.find_by(id: metadata["owner_id"])
  end

  # Do not send investigation_updated mail. This is handled by the DeleteUser service
  def notify_relevant_users; end
end
