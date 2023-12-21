FactoryBot.define do
  factory :bulk_products_upload do
    association :investigation, factory: :notification
    association :user

    trait :submitted do
      submitted_at { Time.zone.now }
    end
  end
end
