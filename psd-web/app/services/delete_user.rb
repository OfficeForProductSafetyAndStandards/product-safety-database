class DeleteUser
  include Interactor

  def call
    context.fail!(error: "No user supplied") unless context.user
    context.fail!(error: "User already deleted") if context.user.deleted?
    context.fail!(error: "User does not belong to a team so their investigations can't be reassigned") if context.user.teams.empty?

    ActiveRecord::Base.transaction do
      context.user.mark_as_deleted!
      assign_user_investigations_to_their_team
    end
  end

private

  def assign_user_investigations_to_their_team
    # Even when an user belonging to multiple teams is a possibility, users should belong
    # to a single team. This is planned to be enforced in guture.
    context.team = context.user.teams.first

    context.user.investigations.each do |investigation|
      investigation.assignable = context.team
      investigation.save!
      AuditActivity::Investigation::AutomaticallyReassign.from(investigation)
    end
  end
end
