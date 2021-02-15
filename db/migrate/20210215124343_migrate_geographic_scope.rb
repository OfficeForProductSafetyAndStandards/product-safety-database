class MigrateGeographicScope < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      reversible do |dir|
        dir.up do
          CorrectiveAction.find_each do |corrective_action|
            CorrectiveAction.migrate_geographical_scope(corrective_action)
          end
        end
      end
    end
  end
end
