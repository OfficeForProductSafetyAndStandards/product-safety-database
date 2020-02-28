FactoryBot.define do
  factory :user do
    id { SecureRandom.uuid }
    name { "test user" }
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
      after(:build) do |user|
        mailer = instance_double("NotifyMailer", welcome: instance_double("ActionMailer::MessageDelivery", deliver_later: true))
        UserDeclarationService.accept_declaration(user, mailer)
      end
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

    after(:create) do |user, evaluator|
      allow(KeycloakClient.instance).to receive(:get_user_roles).with(user.id).and_return(evaluator.roles)
      user.load_roles_from_keycloak
    end
  end
end
