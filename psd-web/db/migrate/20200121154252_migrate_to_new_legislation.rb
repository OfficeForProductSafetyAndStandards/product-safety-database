class MigrateToNewLegislation < ActiveRecord::Migration[5.2]
  NEW_LEGISTLATION_MAPPING = {
    "Equipment and Protective Systems Intended for Use in Potentially Explosive Atmospheres Regulations 2016" => "ATEX 2016",
    "Consumer Protection Act 1987 (Part 1)" => "Consumer Protection Act 1987",
    "Aerosol Dispensers Regulations 2009" => "Aerosol Dispensers Regulations 2009 (Consumer Protection Act 1987)",
    "Cosmetic Products Enforcement Regulations 2013 / EC 1223/2009 Cosmetic Products" => "Cosmetic Products Enforcement Regulations 2013",
    "Furniture and Furnishings (Fire) (Safety) Regulations 1988" =>  "Furniture and Furnishings (Fire)(Safety) Regulations 1988",
    "Gas Appliances (Enforcement) and Miscellaneous Amendments Regulations 2018 / EU 2016/426 Appliances Burning Gaseous Fuels" => "Gas Appliances (Enforcement) and Miscellaneous Amendments Regulations 2018",
    "Nightwear Safety Regulations 1985" => "Nightwear (Safety) Regulations 1985",
    "Noise Emission in the Environment by Equipment for Use Outdoors Regulations 20011" => "Noise Emission in Environment by Equipment for use Outdoors (Amendment) Regulations 2015",
    "Personal Protective Equipment (Enforcement) Regulations 2018 / EU 2016/425 Personal Protective Equipment" => "Personal Protective Equipment (Enforcement) Regulations 2018",
    "Plugs and Sockets (Safety) Regulations 1994" => "Plugs and Sockets etc. (Safety) Regulations 1994",
    "Pressure Equipment Regulations 2016" => "Pressure Equipment (Safety) Regulations 2016",
    "Toys Safety Regulations 2011" => "Toys (Safety) Regulations 2011 (Consumer Protection Act 1987)"
  }
  def up
    NEW_LEGISTLATION_MAPPING.each do |old_legislation_name, new_legislation_name|
      CorrectiveAction.where(legislation: old_legislation_name).update_all(legislation: new_legislation_name)
      Test.where(legislation: old_legislation_name).update_all(legislation: new_legislation_name)
    end
  end

  def down
    NEW_LEGISTLATION_MAPPING.each do |old_legislation_name, new_legislation_name|
      CorrectiveAction.where(legislation: new_legislation_name).update_all(legislation: old_legislation_name)
      Test.where(legislation: new_legislation_name).update_all(legislation: old_legislation_name)
    end
  end
end
