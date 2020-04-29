class AuditActivity::Investigation::AutomaticallyReassign < AuditActivity::Investigation::Base
  def self.from(investigation)
    title = investigation.assignable.id.to_s
    super(investigation, title)
  end

  def assignable_id
    # We store assignable_id in title field, this is getting it back
    # Using alias for accessing parent method causes errors elsewhere :(
    AuditActivity::Investigation::Base.instance_method(:title).bind(self).call
  end

  # We store assignable_id in title field, this is computing title based on that
  def title
    type = investigation.case_type.capitalize
    new_assignable = (User.find_by(id: assignable_id) || Team.find_by(id: assignable_id))&.display_name
    "#{type} automatically reassigned to #{new_assignable}"
  end

  def subtitle
    "Automatically reassigned, #{pretty_date_stamp}"
  end

  def entities_to_notify
    []
  end

  def email_subject_text; end

  def email_update_text; end
end
