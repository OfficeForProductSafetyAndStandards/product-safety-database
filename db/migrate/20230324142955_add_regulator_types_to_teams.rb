class AddRegulatorTypesToTeams < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      create_table :regulators do |t|
        t.timestamps
        t.column :name, :string
      end

      change_table :teams, bulk: true do |t|
        t.column :internal_opss, :boolean, default: false
        t.column :local_authority, :boolean, default: false
        t.column :external_regulator, :boolean, default: false
        t.references :regulator, index: false
      end
    end

    Rake::Task["teams:add_regulator_information_to_teams"].invoke(Rails.root.join("lib/regulators/regulators.xlsx").to_s)
  end

  def down
    safety_assured do
      change_table :teams, bulk: true do |t|
        t.remove :internal_opss
        t.remove :local_authority
        t.remove :external_regulator
        t.remove_references :regulator
      end

      drop_table :regulators
    end
  end
end
