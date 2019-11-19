FactoryBot.define do
  factory :user do
    id { SecureRandom.uuid }
    name { "test" }
    email { "test@example.com" }
    organisation
    has_accepted_declaration { false }
    has_been_sent_welcome_email { true }
    has_viewed_introduction { false }
    account_activated { false }

    trait :activated do
      has_accepted_declaration { true }
      account_activated { true }
    end
  end
end
