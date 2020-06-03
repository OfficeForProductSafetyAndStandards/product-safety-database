class Collaboration < ApplicationRecord
  belongs_to :investigation
  belongs_to :collaborator, polymorphic: true
end
