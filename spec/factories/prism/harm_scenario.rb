FactoryBot.define do
  factory :prism_harm_scenario, class: "Prism::HarmScenario" do
    association :risk_assessment, factory: :prism_risk_assessment

    description { Faker::Quote.matz }
  end
end
