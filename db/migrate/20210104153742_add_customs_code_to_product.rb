class AddCustomsCodeToProduct < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_column :products, :customs_code, :text
    end
  end
end
