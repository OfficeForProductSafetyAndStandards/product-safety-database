class AddRetiredAtToProducts < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_column :products, :retired_at, :datetime
    add_index :products, :retired_at, algorithm: :concurrently
  end
end
