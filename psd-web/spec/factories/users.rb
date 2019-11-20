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

    transient do
      roles { [:psd_user] }
    end

    trait :activated do
      has_accepted_declaration { true }
      account_activated { true }
    end

    trait :inactive do
      account_activated { false }
    end

    trait :team_admin do
      transient do
        roles { %i[psd_user team_admin] }
      end
    end

    trait :psd_user do
      transient do
        roles { [:psd_user] }
      end
    end

    trait :opss_user do
      transient do
        roles { %i[psd_user opss_user] }
      end
    end

    after(:build) do |model, evaluator|
      model.instance_variable_set(:@roles, evaluator.roles)
    end
  end
end
