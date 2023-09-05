FactoryBot.define do
  factory :prism_harm_scenario, class: "Prism::HarmScenario" do
    association :risk_assessment, factory: :prism_risk_assessment

    description { Faker::Quote.matz }
    tasks_status do
      {
        "choose_hazard_type" => "not_started",
        "identify_who_might_be_harmed" => "not_started",
        "add_steps_to_harm" => "not_started",
        "determine_severity_of_harm" => "not_started",
        "estimate_probability_of_harm" => "not_started",
        "check_your_harm_scenario" => "not_started"
      }
    end
  end
end
