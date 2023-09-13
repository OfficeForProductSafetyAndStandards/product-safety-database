FactoryBot.define do
  factory :prism_associated_investigation_product, class: "Prism::AssociatedInvestigationProduct" do
    association :associated_investigation, factory: :prism_associated_investigation

    product { create(:product) }
  end
end
