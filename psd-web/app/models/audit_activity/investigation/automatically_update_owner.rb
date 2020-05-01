class AuditActivity::Investigation::AutomaticallyUpdateOwner < AuditActivity::Investigation::Base
  def self.from(investigation)
    title = investigation.owner.id.to_s
    super(investigation, title)
  end

  def owner_id
    # We store owner_id in title field, this is getting it back
    # Using alias for accessing parent method causes errors elsewhere :(
    AuditActivity::Investigation::Base.instance_method(:title).bind(self).call
  end

  # We store owner_id in title field, this is computing title based on that
  def title
    type = investigation.case_type.capitalize
    new_owner = (User.find_by(id: owner_id) || Team.find_by(id: owner_id))&.decorate&.display_name
    "Case owner automatically changed on #{type} to #{new_owner}"
  end

  def subtitle
    "Case owner automatically changed, #{pretty_date_stamp}"
  end

  def entities_to_notify
    []
  end

  def email_subject_text; end

  def email_update_text; end
end
