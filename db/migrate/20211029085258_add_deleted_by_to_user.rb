class AddDeletedByToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :deleted_by, :string
  end
end
