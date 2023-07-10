# This migration comes from prism (originally 20230707101527)
class AddOtherHazardTypeToPrismHarmScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :prism_harm_scenarios, :other_hazard_type, :string
  end
end
