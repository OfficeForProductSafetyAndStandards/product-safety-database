class MigrateGeographicScope < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      reversible do |dir|
        dir.up do
          CorrectiveAction.find_each do |corrective_action|
            corrective_action.update!(geographic_scopes: [corrective_action.geographic_scope])
          end
        end

        dir.down do
          CorrectiveAction.find_each do |corrective_action|
            corrective_action.update!(geographic_scope: corrective_action.geographic_scopes.first)
          end
        end
      end
    end
  end
end
