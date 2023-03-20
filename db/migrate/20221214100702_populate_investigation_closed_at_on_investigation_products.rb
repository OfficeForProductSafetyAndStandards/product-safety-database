class PopulateInvestigationClosedAtOnInvestigationProducts < ActiveRecord::Migration[6.1]
  def up
    ApplicationRecord.connection.exec_update "UPDATE investigation_products SET investigation_closed_at = investigations.date_closed FROM investigations WHERE investigations.id = investigation_products.investigation_id AND investigation_products.investigation_closed_at IS NULL AND investigations.date_closed IS NOT NULL"
  end
end
