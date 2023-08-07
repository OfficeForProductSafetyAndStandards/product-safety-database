class AddTasksStatusToPrismHarmScenarios < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :prism_harm_scenarios, :tasks_status, :json, default: {}
    end
  end
end
