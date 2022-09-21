class MoveInvestigationProductFields < ActiveRecord::Migration[6.1]
  # rubocop:disable Rails/BulkChangeTable
  def up
    add_column :investigation_products, :batch_number, :string
    add_column :investigation_products, :customs_code, :text
    add_column :investigation_products, :number_of_affected_units, :text
    add_column :investigation_products, :affected_units_status, :affected_units_statuses

    ActiveRecord::Base.connection.execute("UPDATE investigation_products
            SET
              batch_number = products.batch_number,
              customs_code = products.customs_code,
              number_of_affected_units = products.number_of_affected_units,
              affected_units_status = products.affected_units_status
            FROM products
              WHERE investigation_products.product_id = products.id")

    safety_assured do
      remove_columns :products, :batch_number, :customs_code, :number_of_affected_units, :affected_units_status
    end
  end

  def down
    add_column :products, :batch_number, :string
    add_column :products, :customs_code, :text
    add_column :products, :number_of_affected_units, :text
    add_column :products, :affected_units_status, :affected_units_statuses

    ActiveRecord::Base.connection.execute("UPDATE products
            SET
              batch_number = investigation_products.batch_number,
              customs_code = investigation_products.customs_code,
              number_of_affected_units = investigation_products.number_of_affected_units,
              affected_units_status = investigation_products.affected_units_status
            FROM investigation_products
              WHERE products.id = investigation_products.product_id")

    safety_assured do
      remove_columns :investigation_products, :batch_number, :customs_code, :number_of_affected_units, :affected_units_status
    end
  end
  # rubocop:enable Rails/BulkChangeTable
end
