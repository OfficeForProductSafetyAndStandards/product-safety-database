class RemoveOwnerTypeAndOwnerIdFromInvestigations < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :investigations, :owner_id, :integer
      remove_column :investigations, :owner_type, :string
    end
  end
end
