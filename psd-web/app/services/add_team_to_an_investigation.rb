class AddTeamToAnInvestigation
  include Interactor

  delegate :edit_access, :current_user, :investigation, :collaborator_id, :include_message, :message, to: :context
  def call
    editor = Team.find_by(id: collaborator_id)
    context.edit_access = investigation.edit_accesses.new(
      collaborator: editor,
      include_message: include_message,
      added_by_user: current_user,
      message: message
    )

    begin
      if edit_access.save
        NotifyTeamAddedToCaseJob.perform_later(edit_access)

        AuditActivity::Investigation::TeamAdded.create!(
          source: UserSource.new(user: current_user),
          investigation: investigation,
          title: "#{editor.team.name} added to #{investigation.case_type.downcase}",
          body: edit_access.message.to_s
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
