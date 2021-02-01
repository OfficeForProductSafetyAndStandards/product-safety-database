class AddUsageAndSeverityToAccidentorIncident < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      reversible do |dir|
        dir.up { execute "CREATE TYPE usages AS ENUM ('during_normal_use', 'during_misuse', 'with_adult_supervision', 'without_adult_supervision', 'unknown_usage');" }
        dir.up { execute "CREATE TYPE severities AS ENUM ('serious', 'high', 'medium', 'low', 'unknown_severity', 'other');" }
        dir.up { execute "CREATE TYPE event_types AS ENUM ('accident', 'incident');" }
        dir.down { execute "DROP TYPE IF EXISTS usages;" }
        dir.down { execute "DROP TYPE IF EXISTS severities;" }
        dir.down { execute "DROP TYPE IF EXISTS types;" }
      end
      add_column :accident_or_incidents, :usage, :usages
      add_column :accident_or_incidents, :severity, :severities
      add_column :accident_or_incidents, :event_type, :event_types
    end
  end
end
