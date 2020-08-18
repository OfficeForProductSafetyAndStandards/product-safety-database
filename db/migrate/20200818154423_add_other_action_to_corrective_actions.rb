class AddOtherActionToCorrectiveActions < ActiveRecord::Migration[5.2]
  def change
    add_column :corrective_actions, :other_action, :string
  end
end
