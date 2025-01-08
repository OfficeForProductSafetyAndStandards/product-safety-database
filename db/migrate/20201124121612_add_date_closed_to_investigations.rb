class AddDateClosedToInvestigations < ActiveRecord::Migration[6.0]
  def change
    add_column :investigations, :date_closed, :datetime
  end
end
