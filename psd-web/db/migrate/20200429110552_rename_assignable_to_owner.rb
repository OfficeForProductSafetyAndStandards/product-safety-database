class RenameownerToOwner < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      rename_column :investigations, :owner_type, :owner_type
      rename_column :investigations, :owner_id, :owner_id
    end
  end
end
