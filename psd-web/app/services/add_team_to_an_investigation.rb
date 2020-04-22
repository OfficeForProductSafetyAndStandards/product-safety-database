class AddTeamToAnInvestigation
  include Interactor

  # rubocop:disable Lint/SuppressedException
  def call
    context.collaborator = context.investigation.collaborators.new(
      team_id: context.team_id,
      include_message: context.include_message,
      added_by_user: context.current_user,
      message: context.message
      )

    begin
      if context.collaborator.save
        NotifyTeamAddedToCaseJob.perform_later(context.collaborator)

        AuditActivity::Investigation::TeamAdded.create!(
          source: UserSource.new(user: context.current_user),
          investigation: context.investigation,
          title: "#{context.collaborator.team.name} added to #{context.investigation.case_type.downcase}",
          body: context.collaborator.message.to_s
        )
      else
        context.fail!
      end
    rescue ActiveRecord::RecordNotUnique
      # Collaborator already added, so return successful but without notfiying the team
      # or creating an audit log.
    end
  end
  # rubocop:enable Lint/SuppressedException
end
