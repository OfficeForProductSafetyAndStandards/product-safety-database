FactoryBot.define do
  factory :product_category do
    name { Faker::Restaurant.name }
  end
end
