FactoryBot.define do
  factory :product_subcategory do
    association :product_category

    name { Faker::Restaurant.name }
  end
end
