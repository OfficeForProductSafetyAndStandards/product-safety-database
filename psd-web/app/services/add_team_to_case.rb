class AddTeamToCase
  include Interactor

  delegate :collaboration, :user, :investigation, :team, :message, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No team supplied") unless team.is_a?(Team)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    begin
      context.collaboration = investigation.edit_access_collaborations.create!(
        collaborator: team,
        added_by_user: user,
        message: message
      )

      send_notification_email
      create_activity
    rescue ActiveRecord::RecordNotUnique
      # Collaborator already added, so return successful but without notifying the team
      # or creating an audit log.
    end
  end

private

  def entities_to_notify
    return [team] if team.email.present?

    team.users.active
  end

  def send_notification_email
    entities_to_notify.each do |entity|
      NotifyMailer.team_added_to_case_email(collaboration, to_email: entity.email).deliver_later
    end
  end

  def create_activity
    AuditActivity::Investigation::TeamAdded.create!(
      source: UserSource.new(user: user),
      investigation: investigation,
      title: "#{team.name} added to #{investigation.case_type.downcase}",
      body: collaboration.message.to_s
    )
  end
end
