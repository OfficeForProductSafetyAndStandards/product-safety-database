class CaseCreator < CaseOwner
  belongs_to :investigation, inverse_of: :case_creator, optional: true
end
