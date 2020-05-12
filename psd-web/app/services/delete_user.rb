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
    context.team = context.user.team

    context.user.investigations.each do |investigation|
      investigation.owner = context.team
      investigation.save!
      AuditActivity::Investigation::AutomaticallyUpdateOwner.from(investigation)
    end
  end
end
