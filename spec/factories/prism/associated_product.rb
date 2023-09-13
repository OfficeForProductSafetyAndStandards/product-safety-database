FactoryBot.define do
  factory :prism_associated_product, class: "Prism::AssociatedProduct" do
    association :risk_assessment, factory: :prism_risk_assessment

    product { create(:product) }
  end
end
