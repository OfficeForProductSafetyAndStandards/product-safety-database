class RemoveNullConstrainOnInvestigationIdOnCollaborators < ActiveRecord::Migration[5.2]
  def up
    safety_assured do
      change_column :collaborators, :investigation_id, :integer, null: true
    end
  end

  def down
    safety_assured do
      change_column :collaborators, :investigation_id, :integer, null: false
    end
  end
end
