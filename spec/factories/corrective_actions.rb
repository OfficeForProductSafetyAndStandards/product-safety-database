FactoryBot.define do
  factory :corrective_action do
    association :investigation, factory: :allegation
    product
    action { (CorrectiveAction.actions.keys - %w[other]).sample }
    date_decided_day { date_decided.day }
    date_decided_month { date_decided.month }
    date_decided_year { date_decided.year }
    legislation { Rails.application.config.legislation_constants["legislation"].sample }
    measure_type { CorrectiveAction::MEASURE_TYPES.sample }
    duration { CorrectiveAction::DURATION_TYPES.sample }
    geographic_scope { Rails.application.config.corrective_action_constants["geographic_scope"].sample }
    geographic_scopes { CorrectiveAction::GEOGRAPHIC_SCOPES[0..rand(CorrectiveAction::GEOGRAPHIC_SCOPES.size - 1)] }
    details { Faker::Lorem.sentence }
    related_file { false }

    transient do
      date_decided { Faker::Date.backward(days: 14) }
      owner_id {}
    end

    trait :with_file do
      with_antivirus_checked_document
      related_file { true }
    end
  end
end
