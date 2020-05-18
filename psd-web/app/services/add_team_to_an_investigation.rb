class AddTeamToAnInvestigation
  include Interactor

  delegate :edition, :current_user, :investigation, :collaborator_id, :include_message, :message, to: :context
  def call
    editor = Team.find_by(id: collaborator_id)
    context.edition = investigation.editions.new(
      collaborator: editor,
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
