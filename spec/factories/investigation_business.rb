FactoryBot.define do
  factory :investigation_business do
    association :investigation, factory: :allegation
    association :business
    relationship { "Manufacturer" }
  end
end
