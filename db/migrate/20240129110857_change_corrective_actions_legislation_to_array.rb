class ChangeCorrectiveActionsLegislationToArray < ActiveRecord::Migration[7.0]
  def up
    change_column :corrective_actions, :legislation, :string, array: true, using: "(string_to_array(legislation, ''))"
    change_column_default :corrective_actions, :legislation, []
  end

  def down
    change_column :corrective_actions, :legislation, :string, using: "(array_to_string(legislation, ','))"
    change_column_default :corrective_actions, :legislation, nil
  end
end
