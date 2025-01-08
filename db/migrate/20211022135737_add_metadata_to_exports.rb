class AddMetadataToExports < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      change_table :case_exports, bulk: true do |t|
        t.column :params, :jsonb
        t.column :user_id, :uuid
      end

      change_table :business_exports, bulk: true do |t|
        t.column :params, :jsonb
        t.column :user_id, :uuid
      end

      change_table :product_exports, bulk: true do |t|
        t.column :params, :jsonb
        t.column :user_id, :uuid
      end

      add_index :case_exports, :user_id
      add_index :business_exports, :user_id
      add_index :product_exports, :user_id
    end
  end
end
