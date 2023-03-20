class AddInvestigationClosedAtToInvestigationProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :investigation_products, :investigation_closed_at, :timestamp
  end
end
