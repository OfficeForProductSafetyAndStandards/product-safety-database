class RemoveNullConstraintOnInvestigationsAddedByUserId < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      change_column_null :collaborations, :added_by_user_id, true
    end
  end
end
