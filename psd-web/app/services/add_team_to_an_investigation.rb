class AddTeamToAnInvestigation
  include Interactor

  delegate :collaborator, :current_user, :investigation, :team_id, :include_message, :message, to: :context
  def call
    context.collaborator = investigation.collaborators.new(
      team_id: team_id,
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
          title: "#{collaborator.team.name} added to #{investigation.case_type.downcase}",
          body: collaborator.message.to_s
        )
      else
        context.fail!
      end
    rescue ActiveRecord::RecordNotUnique
      # Collaborator already added, so return successful but without notfiying the team
      # or creating an audit log.
    end
  end
end
