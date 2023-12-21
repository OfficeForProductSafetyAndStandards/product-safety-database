class AddTasksStatusToInvestigations < ActiveRecord::Migration[7.0]
  def change
    add_column :investigations, :tasks_status, :jsonb, default: {}
  end
end
