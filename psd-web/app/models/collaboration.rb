class Collaboration < ApplicationRecord
  belongs_to :investigation, optional: true
  belongs_to :collaborator, polymorphic: true
end
