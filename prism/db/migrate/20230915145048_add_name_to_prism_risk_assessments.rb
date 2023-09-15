class AddNameToPrismRiskAssessments < ActiveRecord::Migration[7.0]
  def change
    add_column :prism_risk_assessments, :name, :string
  end
end
