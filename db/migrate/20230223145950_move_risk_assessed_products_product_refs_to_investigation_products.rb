class MoveRiskAssessedProductsProductRefsToInvestigationProducts < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      add_reference :risk_assessed_products, :investigation_product, index: { algorithm: :concurrently }
      execute "UPDATE risk_assessed_products SET investigation_product_id = ip.id FROM investigations i JOIN risk_assessments ra ON i.id = ra.investigation_id JOIN risk_assessed_products rap ON ra.id = rap.risk_assessment_id JOIN products p ON rap.product_id = p.id JOIN investigation_products ip ON i.id = ip.investigation_id AND p.id = ip.product_id WHERE risk_assessed_products.product_id = p.id;"
      remove_reference :risk_assessed_products, :product, index: { algorithm: :concurrently }
      add_index :risk_assessed_products, [:risk_assessment_id, :investigation_product_id], unique: true, algorithm: :concurrently, name: "index_risk_assessed_products"
    end
  end

  def down
    safety_assured do
      # add_reference :risk_assessed_products, :product, index: { algorithm: :concurrently }
      # execute "UPDATE risk_assessed_products SET product_id = investigation_products.product_id FROM investigation_products WHERE investigation_products.id = risk_assessed_products.investigation_product_id;"
      # remove_reference :risk_assessed_products, :investigation_product, index: { algorithm: :concurrently }
      # we won't be able to re-add the unique index here because it is possible that we will have risk_assessed_products with the same product_id and risk_assessment_id due to multiple versions of the same product being added.
    end
  end
end
