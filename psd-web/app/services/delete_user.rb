class DeleteUser
  include Interactor

  delegate :user, to: :context

  def call
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    context.fail!(error: "User already deleted") if user.deleted?

    ActiveRecord::Base.transaction do
      user.mark_as_deleted!
      change_user_investigations_ownership_to_their_team
    end
  end

private

  def change_user_investigations_ownership_to_their_team
    context.team = context.user.team

    user.investigations.each do |investigation|
      context.team.own!(investigation)

      create_audit_activity_for_case_owner_automatically_changed(investigation)
    end
  end

  def create_audit_activity_for_case_owner_automatically_changed(investigation)
    metadata = activity_class.build_metadata(investigation.owner)

    activity_class.create!(
      source: nil, # DeleteUser is called from rake user:delete where no user source is available
      investigation: investigation,
      title: nil,
      body: nil,
      metadata: metadata
    )
  end

  def activity_class
    AuditActivity::Investigation::AutomaticallyUpdateOwner
  end
end
