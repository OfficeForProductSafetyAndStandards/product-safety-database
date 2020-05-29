FactoryBot.define do
  factory :corrective_action do
    association :investigation, factory: :allegation
    product
    summary { Faker::Lorem.sentence }
    date_decided_day { date_decided.day }
    date_decided_month { date_decided.month }
    date_decided_year { date_decided.year }
    legislation { Rails.application.config.legislation_constants["legislation"].sample }
    measure_type { CorrectiveAction::MEASURE_TYPES.sample }
    duration { CorrectiveAction::DURATION_TYPES.sample }
    geographic_scope { Rails.application.config.corrective_action_constants["geographic_scope"].sample }
    details { Faker::Lorem.sentence }
    related_file { "No" }

    transient do
      date_decided { Faker::Date.backward(days: 14) }
    end

    trait :with_file do
      related_file { "Yes" }
    end
  end
end
