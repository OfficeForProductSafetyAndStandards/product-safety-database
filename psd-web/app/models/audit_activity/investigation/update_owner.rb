class AuditActivity::Investigation::UpdateOwner < AuditActivity::Investigation::Base
  include NotifyHelper

  def self.from(investigation)
    title = investigation.owner.id.to_s
    body = investigation.owner_rationale
    super(investigation, title, sanitize_text(body))
  end

  def owner_id
    # We store owner_id in title field, this is getting it back
    # Using alias for accessing parent method causes errors elsewhere :(
    AuditActivity::Investigation::Base.instance_method(:title).bind(self).call
  end

  def title
    # We store owner_id in title field, this is computing title based on that
    "Case owner changed to #{(User.find_by(id: owner_id) || Team.find_by(id: owner_id))&.decorate&.display_name}"
  end

  def email_update_text(viewer = nil)
    body = []
    body << "Case owner changed on #{investigation.case_type} to #{investigation.owner.decorate.display_name(viewer: viewer)} by #{source&.show(viewer)}."

    if investigation.owner_rationale.present?
      body << "Message from #{source&.show(viewer)}:"
      body << inset_text_for_notify(investigation.owner_rationale)
    end

    body.join("\n\n")
  end

  def email_subject_text
    "Case owner changed for #{investigation.case_type}"
  end

private

  def subtitle_slug
    "Changed"
  end

  def users_to_notify
    compute_relevant_entities(model: User, compute_users_from_entity: proc { |user| [user] })
  end

  def teams_to_notify
    compute_relevant_entities(model: Team, compute_users_from_entity: proc { |team| team.users })
  end

  def compute_relevant_entities(model:, compute_users_from_entity:)
    return [] unless investigation.saved_changes.key?("owner_id")

    previous_owner_id = investigation.saved_changes["owner_id"][0]
    previous_owner = model.find_by(id: previous_owner_id)
    new_owner = investigation.owner
    owner_changed_by = source.user

    old_users = previous_owner.present? ? compute_users_from_entity.call(previous_owner) : []
    old_entities = previous_owner.present? ? [previous_owner] : []
    new_entities = new_owner.is_a?(model) ? [new_owner] : []
    return new_entities if old_users.include? owner_changed_by

    (new_entities + old_entities).uniq
  end
end
