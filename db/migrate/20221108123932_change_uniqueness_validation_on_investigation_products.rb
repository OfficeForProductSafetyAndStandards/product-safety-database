class ChangeUniquenessValidationOnInvestigationProducts < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    remove_index "investigation_products", %w[investigation_id product_id]
    add_index "investigation_products", %w[investigation_id product_id investigation_closed_at], name: "index_investigation_products_on_inv_id_product_id_closed_at", algorithm: :concurrently, unique: true
  end

  def down
    remove_index "investigation_products", %w[investigation_id product_id investigation_closed_at]
    add_index "investigation_products", %w[investigation_id product_id], algorithm: :concurrently, unique: true
  end
end
