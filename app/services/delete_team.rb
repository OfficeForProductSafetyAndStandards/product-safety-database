class DeleteTeam
  include Interactor

  delegate :team, :new_team, :user, to: :context

  def call
    context.fail!(error: "No team supplied") unless team.is_a?(Team)
    context.fail!(error: "No new team supplied") unless new_team.is_a?(Team)
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    context.fail!(error: "Team already deleted") if team.deleted?
    context.fail!(error: "New team cannot be deleted") if new_team.deleted?

    ActiveRecord::Base.transaction do
    end
  end

private

end
