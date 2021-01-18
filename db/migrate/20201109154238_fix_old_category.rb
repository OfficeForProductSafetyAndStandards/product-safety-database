class FixOldCategory < ActiveRecord::Migration[6.0]
  def change
    old_to_new_category_map = {
      ["Low Voltage Equipment (inc. plugs & sockets)",
       "White Goods",
       "Small Electronics",
       "Alarms"] => "Electrical appliances and equipment",
      ["Baby/Children's Products"] => "Childcare articles and children's equipment",
      ["Other Product sub-category"] => "Other",
      ["Furniture & Furnishings"] => "Furniture",
      ["Clothing (inc. baby)"] => "Clothing, textiles and fashion items",
      ["Personal Protective Equipment (PPE)."] => "Personal protective equipment (PPE)",
      ["Measuring Instruments (inc. pressure)"] => "Measuring instruments",
      %w[Lasers] => "Laser pointers"
    }
    safety_assured do
      reversible do |dir|
        dir.up do
          old_to_new_category_map.each do |old_values, new_value|
            Product.where(category: old_values).update_all(category: new_value)
          end
        end
      end
    end
  end
end
