FactoryBot.define do
  sequence :email do |n|
    "user#{n}@example.com"
  end
end

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { generate(:email) }
    organisation
    password { "2538fhdkvuULE36f" }
    password_confirmation(&:password)
    has_accepted_declaration { false }
    has_been_sent_welcome_email { true }
    has_viewed_introduction { false }
    account_activated { false }
    hash_iterations { 27_500 }
    mobile_number { "07700 900 982" }
    mobile_number_verified { true }
    direct_otp_sent_at { Time.zone.now }
    direct_otp { "12345" }
    team { create(:team, organisation:) }

    transient do
      roles { [] }
      team_roles { [] }
    end

    trait :activated do
      has_viewed_introduction { true }
      after(:build) do |user|
        mailer = instance_double("NotifyMailer", welcome: instance_double("ActionMailer::MessageDelivery", deliver_later: true))
        UserDeclarationService.accept_declaration(user, mailer)
      end
    end

    trait :deleted do
      deleted_at { Time.zone.now }
    end

    trait :locked do
      locked_at { Time.zone.now }
      locked_reason { User.locked_reasons.keys.sample }
    end

    trait :inactive do
      account_activated { false }
    end

    trait :invited do
      skip_password_validation { true }
      account_activated { false }
      password { nil }
      password_confirmation { nil }
      mobile_number { nil }
      mobile_number_verified { false }
      last_activity_at_approx { nil }
      name { nil }
    end

    trait :viewed_introduction do
      has_viewed_introduction { true }
    end

    trait :team_admin do
      transient do
        roles { %i[team_admin] }
      end
    end

    trait :all_data_exporter do
      transient do
        roles { %i[all_data_exporter] }
      end
    end

    trait :opss_user do
      transient do
        team_roles { %i[opss] }
      end
    end

    trait :email_alert_sender do
      transient do
        roles { %i[email_alert_sender] }
      end
    end

    trait :restricted_case_viewer do
      transient do
        roles { %i[restricted_case_viewer] }
      end
    end

    trait :super_user do
      transient do
        roles { %i[super_user] }
      end
    end

    after(:create) do |user, evaluator|
      evaluator.roles.each do |role|
        create(:role, name: role, entity: user)
      end

      evaluator.team_roles.each do |role|
        create(:role, name: role, entity: user.team)
      end
    end
  end
end
