FactoryBot.define do
  factory :corrective_action do
    investigation
    product
    summary { Faker::Lorem.sentence }
    date_decided_day { Faker::Date.backward(days: 14).day }
    date_decided_month { Faker::Date.backward(days: 14).month }
    date_decided_year { Faker::Date.backward(days: 14).year }
    legislation { Rails.application.config.legislation_constants["legislation"].sample }
    measure_type { CorrectiveAction::MEASURE_TYPES.sample }
    duration { CorrectiveAction::DURATION_TYPES.sample }
    geographic_scope { Rails.application.config.corrective_action_constants["geographic_scope"].sample }
    details { Faker::Lorem.sentence }
    related_file { "No" }

    trait :with_file do
      related_file { "Yes" }
    end
  end
end
