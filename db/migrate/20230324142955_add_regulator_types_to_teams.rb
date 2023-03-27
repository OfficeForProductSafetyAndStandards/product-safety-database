class AddRegulatorTypesToTeams < ActiveRecord::Migration[7.0]
  def up
    add_column :teams, :internal_opss, :boolean, default: false
    add_column :teams, :local_authority, :boolean, default: false
    add_column :teams, :external_regulator, :boolean, default: false

    Rake::Task["teams:add_regulator_information_to_teams"].invoke(Rails.root.join("lib/regulators/regulators.xlsx").to_s)
  end

  def down
    remove_column :teams, :internal_opss
    remove_column :teams, :local_authority
    remove_column :teams, :external_regulator
  end
end
