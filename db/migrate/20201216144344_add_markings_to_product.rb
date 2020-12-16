class AddMarkingsToProduct < ActiveRecord::Migration[6.0]
  def change
    add_column :products, :markings, :text, array: true, default: nil
  end
end
