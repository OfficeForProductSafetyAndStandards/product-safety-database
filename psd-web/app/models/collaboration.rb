class Collaboration < ApplicationRecord
  belongs_to :investigation
  belongs_to :collaborator, polymorphic: true

  def self.edit_and_read_only
    where(type: ["Collaboration::Access::Edit", "Collaboration::Access::ReadOnly"])
  end

  def creator_team?
    investigation.creator_team == collaborator
  end
end
