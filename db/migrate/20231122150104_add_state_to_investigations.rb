class AddStateToInvestigations < ActiveRecord::Migration[7.0]
  def change
    add_column :investigations, :state, :string
  end
end
