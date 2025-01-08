class AddActionToCorrectiveActionAndMigrateSummaryToOtherAction < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      add_column :corrective_actions, :action, :string, default: "other"
    end
  end

  def down
    remove_column :corrective_actions, :action
  end
end
