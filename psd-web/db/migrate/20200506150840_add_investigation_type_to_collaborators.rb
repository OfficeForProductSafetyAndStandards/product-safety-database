class AddInvestigationTypeToCollaborators < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      add_column :collaborators, :type, :string
      add_column :collaborators, :investigation_type, :string
    end
  end
end
