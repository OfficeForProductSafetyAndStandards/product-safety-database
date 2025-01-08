class CreatePrismEvaluations < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :prism_risk_assessments, bulk: true do |t|
        t.remove :level_of_uncertainty, type: :string
        t.remove :sensitivity_analysis, type: :boolean
      end

      create_table :prism_evaluations, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.references :risk_assessment, type: :uuid
        t.string :level_of_uncertainty
        t.boolean :sensitivity_analysis
        t.string :other_types_of_harm, array: true, default: []
        t.string :number_of_products_expected_to_change
        t.boolean :uncertainty_level_implications_for_risk_management
        t.string :comparable_risk_level
        t.boolean :multiple_casualties
        t.string :significant_risk_differential
        t.boolean :people_at_increased_risk
        t.string :relevant_action_by_others
        t.boolean :factors_to_take_into_account
        t.boolean :other_hazards
        t.string :low_likelihood_high_severity
        t.boolean :risk_to_non_users
        t.string :aimed_at_vulnerable_users
        t.string :designed_to_provide_protective_function
        t.boolean :user_control_over_risk
        t.text :other_risk_perception_matters
        t.string :risk_tolerability
        t.timestamps
      end
    end
  end
end
