class ChangeCaseOwner
  include Interactor
  include NotifyHelper

  delegate :investigation, :owner, :rationale, :user, :old_owner, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No owner supplied") unless owner.is_a?(User) || owner.is_a?(Team)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.old_owner = investigation.owner

    return if old_owner == owner

    ActiveRecord::Base.transaction do
      investigation.owner_team_collaboration.swap_to_edit_access!

      old_collaborator = investigation.collaboration_accesses.find_by(collaborator: owner)
      (old_collaborator || owner).own!(investigation)

      create_audit_activity_for_case_owner_changed
      add_old_owner_as_collaborator
    end

    investigation.reload
    send_notification_email
  end

private

  def create_audit_activity_for_case_owner_changed
    metadata = activity_class.build_metadata(owner, rationale)

    activity_class.create!(
      source: UserSource.new(user: user),
      investigation: investigation,
      title: nil,
      body: nil,
      metadata: metadata
    )
  end

  def activity_class
    AuditActivity::Investigation::UpdateOwner
  end

  def send_notification_email
    entities_to_notify.each do |recipient|
      email = recipient.is_a?(Team) ? recipient.team_recipient_email : recipient.email

      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        email,
        email_body(recipient),
        "Case owner changed for #{investigation.case_type}"
      ).deliver_later
    end
  end

  # Notify the new owner, and the old one if it's not the user making the change
  def entities_to_notify
    entities = [owner]
    entities << old_owner if old_owner != user

    entities.map { |entity|
      return entity.users.active if entity.is_a?(Team) && !entity.team_recipient_email

      entity
    }.flatten.uniq
  end

  def email_body(viewer = nil)
    user_name = user.decorate.display_name(viewer: viewer)
    body = "Case owner changed on #{investigation.case_type} to #{owner.decorate.display_name(viewer: viewer)} by #{user_name}."
    body << "\n\nMessage from #{user_name}: #{inset_text_for_notify(rationale)}" if rationale
    body
  end

  def add_old_owner_as_collaborator
    return if old_owner_and_new_owner_from_same_team?

    edit_access_collaboration = investigation.edit_access_collaborations.new(
      collaborator: old_owner_team,
      include_message: false,
      added_by_user: user,
    )
    edit_access_collaboration.save!
  end

  def old_owner_team
    old_owner.is_a?(Team) ? old_owner : old_owner.team
  end

  def old_owner_and_new_owner_from_same_team?
    old_owner_team == new_owner_team
  end

  def new_owner_team
    owner.is_a?(Team) ? owner : owner.team
  end
end
