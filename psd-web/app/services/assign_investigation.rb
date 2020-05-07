class AssignInvestigation
  include Interactor

  delegate :investigation, :new_collaborating_case_owner, :current_user, to: :context

  def call
    investigation.with_lock do
      swap_with_co_collaborator! || create_new_case_owner!
    end
  end

  def create_new_case_owner!
    investigation.with_lock do
      old_case_owner = investigation.case_owner

      investigation.create_case_owner!(
        added_by_user: current_user,
        team: new_collaborating_case_owner,
        include_message: "Maybe this message should not be required when creating a case creator"
      )

      investigation.co_collaborators.create!(
        added_by_user: old_case_owner.added_by_user,
        team: old_case_owner.team,
        created_at: old_case_owner.created_at,
        include_message: "Maybe this message should not be required when creating a case creator"
      )
    end
  end

  def swap_with_co_collaborator!
    co_collaborator = investigation.co_collaborators.find_by(team: new_collaborating_case_owner)

    return false if co_collaborator.nil?

    co_collaborator.update!(type: CaseOwner, include_message: false)
    investigation.case_owner.update!(type: CoCollaborator, include_message: false)
  end
end
