class ChangeActivityTypeColumn < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      change_column_default :activities, :type, from: "CommentActivity", to: nil
      change_column_null :activities, :type, false
      add_index :activities, :type
    end
  end
end
