class CreateUcrNumbers < ActiveRecord::Migration[7.0]
  def change
    create_table :ucr_numbers do |t|
      t.references :investigation_product
      t.string :number

      t.timestamps
    end
  end
end
