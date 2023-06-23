FactoryBot.define do
  factory :online_marketplace do
    name { Faker::Company.name }

    trait :approved do
      approved { true }
    end
  end
end
