FactoryBot.define do
  factory :prism_associated_investigation, class: "Prism::AssociatedInvestigation" do
    association :risk_assessment, factory: :prism_risk_assessment

    associated_investigation_products { [association(:prism_associated_investigation_product)] }
  end
end
