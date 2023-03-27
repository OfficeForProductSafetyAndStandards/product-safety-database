class AddRegulatorTypesToTeams < ActiveRecord::Migration[7.0]
  def up
    change_table :teams, bulk: true do |t|
      t.column :internal_opss, :boolean, default: false
      t.column :local_authority, :boolean, default: false
      t.column :external_regulator, :boolean, default: false
    end

    Rake::Task["teams:add_regulator_information_to_teams"].invoke(Rails.root.join("lib/regulators/regulators.xlsx").to_s)
  end

  def down
    change_table :teams, bulk: true do |t|
      t.column :internal_opss
      t.column :local_authority
      t.column :external_regulator
    end
  end
end
