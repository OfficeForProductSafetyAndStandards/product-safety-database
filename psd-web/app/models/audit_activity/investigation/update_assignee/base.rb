class AuditActivity::Investigation::UpdateAssignee::Base < AuditActivity::Investigation::Base
  def self.from(investigation, body = nil)
    title = investigation.assignee.id.to_s
    body = self.sanitize_text(body)
    super(investigation, title, body)
  end

  def assignable_id
    # We store assignable_id in title field, this is getting it back
    # Using alias for accessing parent method causes errors elsewhere :(
    AuditActivity::Investigation::Base.instance_method(:title).bind(self).call
  end

  def title
    # We store assignable_id in title field, this is computing title based on that
    "Assigned to #{(User.find_by(id: assignable_id) || Team.find_by(id: assignable_id))&.display_name}"
  end

  def subtitle_slug
    "Assigned"
  end
end
