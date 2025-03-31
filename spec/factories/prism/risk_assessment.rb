FactoryBot.define do
  factory :prism_risk_assessment, class: "Prism::RiskAssessment" do
    risk_type { "normal_risk" }
    state { "draft" }
    name { Faker::Lorem.sentence(word_count: 4) }
    tasks_status do
      {
        "add_assessment_details" => "not_started",
        "add_details_about_products_in_use_and_safety" => "not_started",
        "add_a_number_of_hazards" => "not_started",
        "confirm_overall_product_risk" => "not_started",
        "add_level_of_uncertainty_and_sensitivity_analysis" => "not_started",
        "consider_the_nature_of_the_risk" => "not_started",
        "consider_perception_and_tolerability_of_the_risk" => "not_started",
        "risk_evaluation_outcome" => "not_started",
        "review_and_submit_results_of_the_assessment" => "not_started"
      }
    end

    transient do
      products { [] }
    end

    after(:create) do |risk_assessment, evaluator|
      evaluator.products.each do |product|
        create(:prism_associated_product, risk_assessment: risk_assessment, product: product)
      end
    end

    trait :serious_risk do
      risk_type { "serious_risk" }
      tasks_status do
        {
          "add_evaluation_details" => "not_started",
          "add_level_of_uncertainty_and_sensitivity_analysis" => "not_started",
          "consider_the_nature_of_the_risk" => "not_started",
          "consider_perception_and_tolerability_of_the_risk" => "not_started",
          "risk_evaluation_outcome" => "not_started",
          "review_and_submit_results_of_the_evaluation" => "not_started"
        }
      end
    end

    trait :submitted do
      state { "submitted" }
    end

    trait :with_product do
      associated_products { [association(:prism_associated_product)] }
    end

    trait :with_harm_scenario do
      harm_scenarios { [association(:prism_harm_scenario)] }
    end
  end
end
