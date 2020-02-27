class RemovePathFromTeamAndOrganisation < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :organisations, :path, :string
      remove_column :teams, :path, :string
    end
  end
end
