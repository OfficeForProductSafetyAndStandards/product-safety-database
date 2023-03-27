FactoryBot.define do
  factory :team do
    name { Faker::TvShows::SiliconValley.company }
    team_recipient_email { "#{name.downcase.gsub(/\s/, '.')}@example.com" }
    organisation
    country { "country:GB-ENG" }

    transient do
      roles { [] }
    end

    trait :deleted do
      deleted_at { Time.zone.now }
    end

    trait :internal_opss_team do
      internal_opss_team { true }
    end

    trait :external_regulator do
      external_regulator { true }
      regulator
    end

    trait :local_authority do
      local_authority { true }
      ts_region
    end

    after(:create) do |team, evaluator|
      evaluator.roles.each do |role|
        create(:role, name: role, entity: team)
      end
    end
  end
end
