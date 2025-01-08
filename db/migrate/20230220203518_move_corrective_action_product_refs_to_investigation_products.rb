class MoveCorrectiveActionProductRefsToInvestigationProducts < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      add_reference :corrective_actions, :investigation_product, index: { algorithm: :concurrently }
      execute "UPDATE corrective_actions SET investigation_product_id = investigation_products.id FROM investigation_products WHERE investigation_products.investigation_id = corrective_actions.investigation_id AND investigation_products.product_id = corrective_actions.product_id;"
      remove_reference :corrective_actions, :product, index: { algorithm: :concurrently }
    end
  end

  def down
    safety_assured do
      add_reference :corrective_actions, :product, index: { algorithm: :concurrently }
      execute "UPDATE corrective_actions SET product_id = investigation_products.product_id FROM investigation_products WHERE investigation_products.id = corrective_actions.investigation_product_id;"
      remove_reference :corrective_actions, :investigation_product, index: { algorithm: :concurrently }
    end
  end
end
