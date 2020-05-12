class AddTeamToAnInvestigation
  include Interactor

  delegate :collaborator, :current_user, :investigation, :team_id, :include_message, :message, to: :context
  def call
    team = Team.find_by(id: team_id)
    context.fail!(error: "Team is required") unless team

    return if investigation.collaborators.where(collaborating: team).exists?

    context.collaborator = investigation.collaborators.new(
      collaborating: team,
      include_message: include_message,
      added_by_user: current_user,
      message: message
    )

    begin
      if collaborator.save
        NotifyTeamAddedToCaseJob.perform_later(collaborator)

        AuditActivity::Investigation::TeamAdded.create!(
          source: UserSource.new(user: current_user),
          investigation: investigation,
          title: "#{collaborator.collaborating.name} added to #{investigation.case_type.downcase}",
          body: collaborator.message.to_s
        )
      else
        context.fail!
      end

      context.collaborator = collaborator
    rescue ActiveRecord::RecordNotUnique
      # Collaborator already added, so return successful but without notfiying the team
      # or creating an audit log.
    end
  end
end
