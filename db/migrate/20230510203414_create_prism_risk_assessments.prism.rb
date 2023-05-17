# This migration comes from prism (originally 20230510203120)
class CreatePrismRiskAssessments < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      create_table :prism_risk_assessments, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.string :state
        t.string :risk_type
        t.string :assessor_name
        t.string :assessment_organisation
        t.string :assessed_before
        t.timestamps
      end
    end
  end
end
