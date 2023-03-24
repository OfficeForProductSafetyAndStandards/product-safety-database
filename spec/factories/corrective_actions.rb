FactoryBot.define do
  factory :corrective_action do
    association :investigation, factory: :allegation
    investigation_product
    action { (CorrectiveAction.actions.keys - %w[other]).sample }
    date_decided { Faker::Date.backward(days: 14) }
    legislation { Rails.application.config.legislation_constants["legislation"].sample }
    measure_type { CorrectiveAction::MEASURE_TYPES.sample }
    duration { CorrectiveAction::DURATION_TYPES.sample }
    geographic_scopes { CorrectiveAction::GEOGRAPHIC_SCOPES[0..-2] }
    details { Faker::Lorem.sentence }
    online_recall_information { Faker::Internet.url(host: "example.com") }
    has_online_recall_information { CorrectiveAction.has_online_recall_informations["has_online_recall_information_yes"] }
    transient do
      owner_id {}
    end

    trait :with_file do
      with_antivirus_checked_document
    end
  end
end
