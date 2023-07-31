class MigrateElectromagneticDisturbanceHazards < ActiveRecord::Migration[7.0]
  def change
    Investigation.where(hazard_type: "Electromagnetic").update_all(hazard_type: "Electromagnetic disturbance")
    Investigation.where(hazard_type: "Disturbance").update_all(hazard_type: "Electromagnetic disturbance")
  end
end
