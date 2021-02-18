class AddGeographicScopesToCorrectiveActions < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_column :corrective_actions, :geographic_scopes, :string, array: true, default: "{}"
    end
  end
end
