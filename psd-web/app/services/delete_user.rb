class DeleteUser
  include Interactor

  def call
    context.fail!(error: "No user supplied") unless context.user

    ActiveRecord::Base.transaction do
      context.user.mark_as_deleted!
      assign_user_investigations_to_their_team
    end
  end

private

  def assign_user_investigations_to_their_team
    context.team = context.user.teams.first

    context.user.investigations.each do |investigation|
      AuditActivity::Investigation::DeleteAssignee.from(investigation)
      investigation.assignee = context.team
      investigation.save
    end
  end
end
