FactoryBot.define do
  factory :investigation_product do
    association :investigation, factory: :allegation
    association :product
  end
end
