# This migration comes from prism (originally 20230724144100)
class AddConfirmedAtToPrismHarmScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :prism_harm_scenarios, :confirmed_at, :datetime, precision: nil
  end
end
