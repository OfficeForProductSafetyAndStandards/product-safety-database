class AddNotNullToActionOnCorrectiveActions < ActiveRecord::Migration[5.2]
  def change
    safety_assured { change_column_null :corrective_actions, :action, false }
  end
end
