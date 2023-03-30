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

    after(:create) do |team, evaluator|
      evaluator.roles.each do |role|
        create(:role, name: role, entity: team)
      end
    end
  end
end
