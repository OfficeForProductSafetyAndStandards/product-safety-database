class AssignInvestigation
  include Interactor

  delegate :investigation, :new_collaborating_case_owner, :current_user, to: :context

  def call
    Collaborators::Base.transaction do
      swap_current_case_owners_to_collaborators!
      add_new_case_owner!
    end
  end

private

  def collaborator_attributes
    {
      added_by_user: current_user,
      include_message: false
    }
  end

  def add_new_case_owner!
    if collaborator
      collaborator.make_case_owner!(collaborator_attributes)
    else
      investigation.collaborators
        .create!(collaborator_attributes.merge(collaborating: new_collaborating_case_owner))
    end
  end

  def swap_current_case_owners_to_collaborators!
    investigation.case_owners.each { |case_owner| case_owner.make_collaborator!(collaborator_attributes) }
  end

  def collaborator
    @collaborator ||= investigation.collaborators.find_by(collaborating: new_collaborating_case_owner)
  end
end
