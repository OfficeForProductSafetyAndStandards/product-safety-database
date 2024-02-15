class AddExtraInfomationToTeams < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :teams, bulk: true do |t|
        t.string :team_type
        t.string :regulator_name
        t.string :ts_region
        t.string :ts_acronym
        t.string :ts_area
      end
    end
  end
end
