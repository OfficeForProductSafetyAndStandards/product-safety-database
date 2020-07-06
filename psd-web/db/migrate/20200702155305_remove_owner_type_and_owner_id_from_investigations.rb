class RemoveOwnerTypeAndOwnerIdFromInvestigation < ActiveRecord::Migration[5.2]
  def change
    remove_column :investigations, :owner_id
    remove_column :investigations, :owner_type
  end
end
