class RenameAssignableToOwner < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      rename_column :investigations, :assignable_type, :owner_type
      rename_column :investigations, :assignable_id, :owner_id
    end
  end
end
