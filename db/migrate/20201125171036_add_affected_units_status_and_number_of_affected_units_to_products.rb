class AddAffectedUnitsStatusAndNumberOfAffectedUnitsToProducts < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      reversible do |dir|
        dir.up { execute "CREATE TYPE affected_units_statuses AS ENUM ('exact', 'approx', 'unknown', 'not_relevant');" }
        dir.down { execute "DROP TYPE IF EXISTS affected_units_statuses;" }
      end
      add_column :products, :affected_units_status, :affected_units_statuses
      add_column :products, :number_of_affected_units, :text
    end
  end
end
