FactoryBot.define do
  factory :prism_risk_assessment, class: "Prism::RiskAssessment" do
    risk_type { "normal_risk" }
    state { "draft" }
    tasks_status do
      {
        "add_assessment_details" => "not_started",
        "search_or_add_a_new_product" => "not_started",
        "add_details_about_products_in_use_and_safety" => "not_started",
        "add_a_number_of_hazards_and_subjects_of_harm" => "not_started",
        "choose_hazard_type" => "not_started",
        "add_a_harm_scenario_and_probability_of_harm" => "not_started",
        "determine_severity_of_harm" => "not_started",
        "determine_severity_of_harm_casualties" => "not_started",
        "add_uncertainty_and_sensitivity_analysis" => "not_started",
        "check_your_harm_scenario" => "not_started",
        "confirm_overall_product_risk" => "not_started",
        "complete_product_risk_evaluation" => "not_started",
        "review_and_submit_results_of_the_assessment" => "not_started"
      }
    end

    trait :serious_risk do
      risk_type { "serious_risk" }
      tasks_status do
        {
          "add_evaluation_details" => "not_started",
          "search_or_add_a_new_product" => "not_started",
          "complete_product_risk_evaluation" => "not_started",
          "review_and_submit_results_of_the_evaluation" => "not_started"
        }
      end
    end

    trait :submitted do
      state { "submitted" }
    end

    trait :with_harm_scenario do
      harm_scenarios { [association(:prism_harm_scenario)] }
    end
  end
end
