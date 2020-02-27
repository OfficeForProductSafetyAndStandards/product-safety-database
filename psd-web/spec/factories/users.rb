FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.safe_email }
    organisation
    password { "password" }
    password_confirmation(&:password)
    has_accepted_declaration { false }
    has_been_sent_welcome_email { true }
    has_viewed_introduction { false }
    account_activated { false }
    hash_iterations { 27_500 }

    transient do
      roles { [:psd_user] }
    end

    factory :user_with_teams do
      transient do
        teams_count { 1 }
      end

      after(:create) do |user, evaluator|
        create_list(:team, evaluator.teams_count, users: [user], organisation_id: user.organisation.id)
      end
    end

    trait :activated do
      has_viewed_introduction { true }
      after(:build) do |user|
        mailer = double("mailer", welcome: double("welcome mailer", deliver_later: true))
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
      evaluator.roles.each do |role|
        create(:user_role, name: role, user: user)
      end
    end
  end
end
