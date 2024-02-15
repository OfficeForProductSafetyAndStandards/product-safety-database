FactoryBot.define do
  factory :business do
    company_number { Faker::Number.number(digits: 8) }
    legal_name { Faker::Restaurant.name }
    trading_name { Faker::Restaurant.name }
  end

  trait :online_marketplace do
    transient do
      notification_to_add { create(:notification) }
      business_relationship { "online_marketplace" }
    end

    after(:create) do |business, evaluator|
      AddBusinessToNotification.call!(notification: evaluator.notification_to_add, business:, relationship: evaluator.business_relationship, user: evaluator.notification_to_add.owner)
      business.reload # This ensures notification.businesses returns business_to_add
    end
  end

  trait :manufacturer do
    transient do
      notification_to_add { create(:notification) }
      business_relationship { "manufacturer" }
    end

    after(:create) do |business, evaluator|
      AddBusinessToNotification.call!(notification: evaluator.notification_to_add, business:, relationship: evaluator.business_relationship, user: evaluator.notification_to_add.owner)
      business.reload # This ensures notification.businesses returns business_to_add
    end
  end

  trait :retailer do
    transient do
      notification_to_add { create(:notification) }
      business_relationship { "retailer" }
    end

    after(:create) do |business, evaluator|
      AddBusinessToNotification.call!(notification: evaluator.notification_to_add, business:, relationship: evaluator.business_relationship, user: evaluator.notification_to_add.owner)
      business.reload # This ensures notification.businesses returns business_to_add
    end
  end
end
