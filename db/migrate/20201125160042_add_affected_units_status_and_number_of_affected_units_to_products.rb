class AddAffectedUnitsStatusAndNumberOfAffectedUnitsToProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :products, :affected_units_status, :string
    add_column :products, :number_of_affected_units, :integer
  end
end
