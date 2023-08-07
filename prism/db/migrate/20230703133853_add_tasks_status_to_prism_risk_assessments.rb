class AddTasksStatusToPrismRiskAssessments < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :prism_risk_assessments, :tasks_status, :json, default: {}
    end
  end
end
