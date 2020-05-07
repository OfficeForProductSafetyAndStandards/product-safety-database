class CaseOwner < Collaborator
  belongs_to :investigation, inverse_of: :case_owner
end
