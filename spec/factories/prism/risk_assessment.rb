FactoryBot.define do
  factory :prism_risk_assessment, class: "Prism::RiskAssessment" do
    risk_type { "normal_risk" }

    trait :serious_risk do
      risk_type { "serious_risk" }
    end
  end
end
