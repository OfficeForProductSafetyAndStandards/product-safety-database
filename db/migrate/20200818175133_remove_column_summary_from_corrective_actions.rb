class RemoveColumnSummaryFromCorrectiveActions < ActiveRecord::Migration[5.2]
  def change
    safety_assured { remove_column :corrective_actions, :summary, :text }
  end
end
