class AddOverallProductRiskLevelToPrismRiskAssessments < ActiveRecord::Migration[7.0]
  def change
    add_column :prism_risk_assessments, :overall_product_risk_level, :string
  end
end
