class CaseOwner < Owner
  belongs_to :investigation, inverse_of: :case_owner, optional: true
end
