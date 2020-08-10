class ChangeRiskLevelToEnum < ActiveRecord::Migration[5.2]
  def up
    safety_assured do
      execute <<-SQL
        CREATE TYPE risk_levels AS ENUM ('serious', 'high', 'medium', 'low', 'other');
      SQL
      remove_column :investigations, :risk_level, :integer
      add_column :investigations, :risk_level, :risk_levels
    end
  end

  def down
    safety_assured do
      remove_column :investigations, :risk_level

      execute <<-SQL
        DROP TYPE risk_levels;
      SQL
    end
  end
end
