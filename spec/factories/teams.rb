FactoryBot.define do
  factory :team do
    name { Faker::TvShows::SiliconValley.company }
    team_recipient_email { "#{name.downcase.gsub(/\s/, '.')}@example.com" }
    organisation

    trait :deleted do
      deleted_at { Time.current }
    end
  end
end
