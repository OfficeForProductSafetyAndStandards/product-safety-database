class CreateProductExports < ActiveRecord::Migration[6.1]
  def change
    create_table :product_exports do |t|

      t.timestamps
    end
  end
end
