class AddNotConclusiveToRiskLevelsEnum < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      execute "ALTER TYPE risk_levels ADD VALUE 'not_conclusive'"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
