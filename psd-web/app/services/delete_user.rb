class DeleteUser
  include Interactor

  def call
    context.fail!(error: "No user supplied") unless context.user
    context.fail!(error: "User already deleted") if context.user.deleted?

    ActiveRecord::Base.transaction do
      context.user.mark_as_deleted!
      assign_user_investigations_to_their_team
    end
  end

private

  def assign_user_investigations_to_their_team
    context.team = context.user.teams.first

    context.user.investigations.each do |investigation|
      investigation.assignee = context.team
      investigation.save
      AuditActivity::Investigation::AutomaticallyReassign.from(investigation)
    end
  end
end
