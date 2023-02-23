class MoveAllProductsOnAuditTrailsToUseInvestigationProducts < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      add_reference :activities, :investigation_product, index: { algorithm: :concurrently }
      execute "UPDATE activities SET investigation_product_id = investigation_products.id FROM investigation_products WHERE investigation_products.investigation_id = activities.investigation_id AND investigation_products.product_id = activities.product_id;"
      remove_reference :activities, :product, index: { algorithm: :concurrently }
    end
  end

  def down
    safety_assured do
      add_reference :activities, :product, index: { algorithm: :concurrently }
      execute "UPDATE activities SET product_id = investigation_products.product_id FROM investigation_products WHERE investigation_products.id = activities.investigation_product_id;"
      remove_reference :activities, :investigation_product, index: { algorithm: :concurrently }
    end
  end
end
