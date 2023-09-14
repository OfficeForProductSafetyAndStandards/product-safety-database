# This migration comes from prism (originally 20230915145048)
class AddNameToPrismRiskAssessments < ActiveRecord::Migration[7.0]
  def change
    add_column :prism_risk_assessments, :name, :string
  end
end
