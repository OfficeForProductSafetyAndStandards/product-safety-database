class MigrateSummaryToOtherAction < ActiveRecord::Migration[5.2]
  def change
    CorrectiveAction.find_each do |corrective_action|
      corrective_action.update_column(:other_action, corrective_action.summary)
    end
  end
end
