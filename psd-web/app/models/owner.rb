class Owner < Collaborator
  belongs_to :investigation, inverse_of: :owners, optional: true
end
