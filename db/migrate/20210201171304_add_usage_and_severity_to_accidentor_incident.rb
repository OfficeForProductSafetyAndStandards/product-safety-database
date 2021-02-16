class AddUsageAndSeverityToAccidentorIncident < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      reversible do |dir|
        dir.up { execute "CREATE TYPE usages AS ENUM ('during_normal_use', 'during_misuse', 'with_adult_supervision', 'without_adult_supervision', 'unknown_usage');" }
        dir.up { execute "CREATE TYPE severities AS ENUM ('serious', 'high', 'medium', 'low', 'unknown_severity', 'other');" }
        dir.down { execute "DROP TYPE IF EXISTS usages;" }
        dir.down { execute "DROP TYPE IF EXISTS severities;" }
      end
      add_column :unexpected_events, :usage, :usages
      add_column :unexpected_events, :severity, :severities
    end
  end
end
