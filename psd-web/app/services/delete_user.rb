class DeleteUser
  include Interactor

  def call
    context.fail!(error: "No user supplied") unless context.user
    context.fail!(error: "User already deleted") if context.user.deleted?

    ActiveRecord::Base.transaction do
      context.user.mark_as_deleted!
      change_user_investigations_ownership_to_their_team
    end
  end

private

  def change_user_investigations_ownership_to_their_team
    # Even when an user belonging to multiple teams is a possibility, users should belong
    # to a single team. This is planned to be enforced in guture.
    context.team = context.user.teams.first

    context.user.investigations.each do |investigation|
      investigation.owner = context.team
      investigation.save!
      AuditActivity::Investigation::AutomaticallyUpdateOwner.from(investigation)
    end
  end
end
