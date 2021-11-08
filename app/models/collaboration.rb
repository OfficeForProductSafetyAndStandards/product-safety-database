class Collaboration < ApplicationRecord
  belongs_to :investigation
  belongs_to :collaborator, polymorphic: true

  redacted_export_with :id, :added_by_user_id, :collaborator_id, :collaborator_type, :created_at,
                       :investigation_id, :message, :type, :updated_at

  def creator_team?
    investigation.creator_team == collaborator
  end
end
