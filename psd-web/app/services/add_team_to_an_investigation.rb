class AddTeamToAnInvestigation
  include Interactor

  delegate :edition, :current_user, :investigation, :team_id, :include_message, :message, to: :context
  def call
    collaborator = Team.find_by(id: team_id)
    context.edition = investigation.editions.new(
      collaborator: collaborator,
      include_message: include_message,
      added_by_user: current_user,
      message: message
    )

    begin
      if edition.save
        NotifyTeamAddedToCaseJob.perform_later(edition)

        AuditActivity::Investigation::TeamAdded.create!(
          source: UserSource.new(user: current_user),
          investigation: investigation,
          title: "#{editor.team.name} added to #{investigation.case_type.downcase}",
          body: edition.message.to_s
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
