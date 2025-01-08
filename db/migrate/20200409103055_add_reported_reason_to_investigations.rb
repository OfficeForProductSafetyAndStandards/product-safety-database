class AddReportedReasonToInvestigations < ActiveRecord::Migration[5.2]
  def up
    safety_assured do
      execute <<-SQL
        CREATE TYPE reported_reasons AS ENUM ('unsafe', 'non_compliant', 'unsafe_and_non_compliant', 'safe_and_compliant');
      SQL

      add_column :investigations, :reported_reason, :reported_reasons
    end
  end

  def down
    safety_assured do
      remove_column :investigations, :reported_reason

      execute <<-SQL
        DROP TYPE reported_reasons;
      SQL
    end
  end
end
