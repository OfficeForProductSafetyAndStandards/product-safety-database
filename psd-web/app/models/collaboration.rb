class Collaboration < ApplicationRecord
  belongs_to :investigation, optional: true
  belongs_to :collaborator, polymorphic: true

  def creator_team?
    investigation.creator_team == collaborator
  end
end
