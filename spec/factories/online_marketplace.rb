FactoryBot.define do
  factory :online_marketplace do
    name { Faker::Company.name }

    trait :approved do
      approved_by_opss { true }
    end
  end
end
