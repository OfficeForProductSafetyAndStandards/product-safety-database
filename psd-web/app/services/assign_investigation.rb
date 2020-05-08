class AssignInvestigation
  include Interactor

  delegate :investigation, :new_collaborating_case_owner, :current_user, to: :context

  def call
    swap_case_owner_to_co_collaborator!
    create_new_case_owner!
  end

  def create_new_case_owner!
    return if investigation.owners.exists?(team: new_collaborating_case_owner)

    investigation.owners.create!(
      type: "CaseOwner",
      added_by_user: current_user,
      collaborating: new_collaborating_case_owner,
      include_message: "Maybe this message should not be required when creating a case creator"
    )
  end

  def swap_case_owner_to_co_collaborator!
    collaborator = investigation.collaborators.find_by(team: new_collaborating_case_owner)

    if collaborator
      return if investigation.case_owner == collaborator
      return if investigation.case_owner.is_a?(CaseCreator)

      investigation.case_owner.update!(type: "CoCollaborator", include_message: false)
      # make sure to flush the case_owner cached relation
      # so the case_owner is either fetched from the database or is nil
      investigation.reload
    end
  end
end
