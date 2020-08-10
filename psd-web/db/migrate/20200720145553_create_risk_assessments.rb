class CreateRiskAssessments < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      create_table :risk_assessments do |t|
        t.integer :investigation_id, null: false
        t.date :assessed_on, null: false
        t.uuid :assessed_by_team_id
        t.integer :assessed_by_business_id
        t.text :assessed_by_other
        t.text :details
        t.text :custom_risk_level
        t.uuid :added_by_user_id, null: false
        t.uuid :added_by_team_id, null: false

        t.timestamps
      end

      add_column :risk_assessments, :risk_level, :risk_levels

      add_foreign_key :risk_assessments, :investigations
      add_foreign_key :risk_assessments, :teams, column: :assessed_by_team_id
      add_foreign_key :risk_assessments, :businesses, column: :assessed_by_business_id
      add_foreign_key :risk_assessments, :users, column: :added_by_user_id
      add_foreign_key :risk_assessments, :teams, column: :added_by_team_id

      create_table :risk_assessed_products do |t|
        t.integer :risk_assessment_id, null: false
        t.integer :product_id, null: false

        t.timestamps
      end

      add_foreign_key :risk_assessed_products, :risk_assessments
      add_foreign_key :risk_assessed_products, :products
      add_index :risk_assessed_products, %i[risk_assessment_id product_id], unique: true, name: "index_risk_assessed_products"
    end
  end
end
