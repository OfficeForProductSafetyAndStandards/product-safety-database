FactoryBot.define do
  factory :business do
    company_number { Faker::Number.number(digits: 8) }
    legal_name { Faker::Restaurant.name }
    trading_name { Faker::Restaurant.name }
  end
end
