class AddMarkingsToProduct < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      reversible do |dir|
        dir.up { execute "CREATE TYPE has_markings_values AS ENUM ('markings_yes', 'markings_no', 'markings_unknown');" }
        dir.down { execute "DROP TYPE IF EXISTS has_markings_values;" }
      end

      change_table :products, bulk: true do |t|
        t.column :has_markings, :has_markings_values, default: nil
        t.column :markings, :text, array: true
      end
    end
  end
end
