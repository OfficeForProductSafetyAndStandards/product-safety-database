# This migration comes from prism (originally 20230824144801)
class AddOverallProductRiskMethodologyAndLabelToPrismRiskAssessments < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :prism_risk_assessments, bulk: true do |t|
        t.string :overall_product_risk_methodology
        t.string :overall_product_risk_plus_label
      end
    end
  end
end
