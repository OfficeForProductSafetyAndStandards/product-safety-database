class AddConstraintsOnCollaborations < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      change_column_null :collaborations, :collaborator_type, false
      change_column_null :collaborations, :type, false
    end
  end
end
