class MoveTestResultProductRefsToInvestigationProducts < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      add_reference :tests, :investigation_product, index: { algorithm: :concurrently }
      execute "UPDATE tests SET investigation_product_id = investigation_products.id FROM investigation_products WHERE investigation_products.investigation_id = tests.investigation_id AND investigation_products.product_id = tests.product_id;"
      remove_reference :tests, :product, index: { algorithm: :concurrently }
    end
  end

  def down
    safety_assured do
      add_reference :tests, :product, index: { algorithm: :concurrently }
      execute "UPDATE tests SET product_id = investigation_products.product_id FROM investigation_products WHERE investigation_products.id = tests.investigation_product_id;"
      remove_reference :tests, :investigation_product, index: { algorithm: :concurrently }
    end
  end

end
