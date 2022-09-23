class RemoveRapexImports < ActiveRecord::Migration[6.1]
  def change
    drop_table :rapex_imports do |t|
      t.datetime "created_at", null: false
      t.string "reference", null: false
      t.datetime "updated_at", null: false
    end
  end
end
