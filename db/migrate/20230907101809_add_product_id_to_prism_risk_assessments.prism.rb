# This migration comes from prism (originally 20230907101621)
class AddProductIdToPrismRiskAssessments < ActiveRecord::Migration[7.0]
  def change
    add_column :prism_risk_assessments, :product_id, :bigint
  end
end
