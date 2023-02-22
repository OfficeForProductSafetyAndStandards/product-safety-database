class MoveUnexpectedEventsProductRefsToInvestigationProducts < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      add_reference :unexpected_events, :investigation_product, index: { algorithm: :concurrently }
      execute "UPDATE unexpected_events SET investigation_product_id = investigation_products.id FROM investigation_products WHERE investigation_products.investigation_id = unexpected_events.investigation_id AND investigation_products.product_id = unexpected_events.product_id;"
      remove_reference :unexpected_events, :product, index: { algorithm: :concurrently }
    end
  end

  def down
    safety_assured do
      add_reference :unexpected_events, :product, index: { algorithm: :concurrently }
      execute "UPDATE unexpected_events SET product_id = investigation_products.product_id FROM investigation_products WHERE investigation_products.id = unexpected_events.investigation_product_id;"
      remove_reference :unexpected_events, :investigation_product, index: { algorithm: :concurrently }
    end
  end
end
