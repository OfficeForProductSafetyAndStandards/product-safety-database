class AddDeletedAtAndDeletedByToInvestigations < ActiveRecord::Migration[6.1]
  def change
    add_column :investigations, :deleted_at, :datetime
    add_column :investigations, :deleted_by, :string
  end
end
