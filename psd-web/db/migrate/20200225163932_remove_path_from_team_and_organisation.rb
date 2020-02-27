class RemovePathFromTeamAndOrganisation < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :organisations, :path
      remove_column :teams, :path
    end
  end
end
