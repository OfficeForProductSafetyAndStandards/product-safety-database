FactoryBot.define do
  factory :investigation do
    user_title { "investigation title" }
    hazard_type { "hazard type" }
    hazard_description { "hazard description" }
    non_compliant_reason { "non compliant reason" }
    complainant_reference { "complainant reference" }
    date_received { 1.day.ago }
    received_type { %w(email phone other).sample }
    is_closed { false }

    association :assignee, factory: :user

    factory :allegation, class: Investigation::Allegation do
      description { "test allegation" }
      user_title { "test allegation title" }
    end

    factory :enquiry, class: Investigation::Enquiry do
      description { "test enquiry" }
      user_title { "test enquiry title" }
    end

    factory :project, class: Investigation::Project do
      description { "test project" }
      user_title { "test project title" }
    end

    trait :with_document do
      transient do
        document_file { Rails.root + "test/fixtures/files/test_result.txt" }
        document_title { Faker::Lorem.sentence }
        document_description { Faker::Lorem.paragraph }
      end

      after :create do |investigation, evaluator|
        file = ActiveStorage::Blob.create_after_upload!(io: File.open(evaluator.document_file), filename: File.basename(evaluator.document_file), content_type: "text/plain", metadata: {
          title: evaluator.document_title,
          description: evaluator.document_description,
          updated: Time.now.iso8601
        })

        investigation.documents.attach(file)
      end
    end

    trait :with_business do
      transient do
        business_to_add { create(:business) }
        business_relationship { "Manufacturer" }
      end

      after(:create) do |investigation, evaluator|
        investigation.add_business(evaluator.business_to_add, evaluator.business_relationship)
        investigation.reload # This ensures investigation.businesses returns business_to_add
      end
    end
  end
end
