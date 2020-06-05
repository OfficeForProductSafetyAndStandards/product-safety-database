class AddConstraintsOnInvestigations < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_index :investigations, :pretty_id
      add_index :investigations, :pretty_id, unique: true
      change_column_null :investigations, :pretty_id, false
    end
  end
end
