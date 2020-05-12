class Collaborator < Collaborators::Current
  def make_case_owner!(collaborator_attributes)
    collaborator_attributes[:type] = "Collaborators::CaseOwnerTeam"
    update!(collaborator_attributes)
  end
end
