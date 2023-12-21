class AuditActivity::Investigation::AutomaticallyUpdateOwner < AuditActivity::Investigation::Base
  def self.build_metadata(owner)
    {
      owner_id: owner.id
    }
  end

  def title(user)
    type = "Notification"
    new_owner = owner.decorate.display_name(viewer: user)
    "Notification owner automatically changed on #{type} to #{new_owner}"
  end

  def subtitle(_viewer)
    "Notification owner automatically changed, #{pretty_date_stamp}"
  end

private

  def owner
    User.find_by(id: metadata["owner_id"]) || Team.find_by(id: metadata["owner_id"])
  end
end
