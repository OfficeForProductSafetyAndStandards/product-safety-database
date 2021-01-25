class AddGeographicScopesToCorrectiveActions < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      reversible do |dir|
        dir.up { execute "CREATE TYPE geographic_scopes AS ENUM ('local', 'great_britain', 'northern_ireland', 'eea_wide', 'eu_wide', 'worldwide', 'unknown');" }
        dir.down { execute "DROP TYPE IF EXISTS geographic_scopes;" }
      end

      add_column :corrective_actions, :geographic_scopes, :geographic_scopes, array: true, default: nil
    end
  end
end
