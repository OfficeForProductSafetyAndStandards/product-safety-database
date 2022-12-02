class ChangeObjectOnVersionsTableFromYamlToJsonb < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      rename_column :versions, :object, :old_object
      add_column :versions, :object, :jsonb
    end
  end
end
