class RemoveDefaultValueForInvestigationsTypeColumn < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      change_column_default :investigations, :type, from: "Investigation::Allegation", to: nil
      change_column_null :investigations, :type, false
    end
  end
end
