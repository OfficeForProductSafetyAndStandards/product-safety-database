FactoryBot.define do
  factory :risk_assessment do
    investigation { association :allegation }
    assessed_on { "2020-07-20" }
    risk_level { (RiskAssessment.risk_levels.values - %w[other]).sample }
    assessed_by_team { association :team }
    assessed_by_business { nil }
    assessed_by_other { nil }
    details { "MyText" }
    investigation_products { [build(:investigation_product)] }
    added_by_user { association :user }
    added_by_team { association :team }

    transient do
      file_description { Faker::Hipster.sentence }
    end

    trait :without_file do
      risk_assessment_file { nil }
    end

    trait :with_file do
      risk_assessment_file { Rack::Test::UploadedFile.new("test/fixtures/files/new_risk_assessment.txt") }

      after(:create) do |risk_assessment, evaluator|
        risk_assessment.risk_assessment_file_blob.metadata["description"] = evaluator.file_description
        risk_assessment.risk_assessment_file_blob.save!
      end
    end
  end
end
