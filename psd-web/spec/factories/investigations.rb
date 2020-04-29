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
    coronavirus_related { false }

    association :owner, factory: :user

    factory :allegation, class: "Investigation::Allegation" do
      description { "test allegation" }
      user_title { "test allegation title" }
    end

    factory :enquiry, class: "Investigation::Enquiry" do
      description { "test enquiry" }
      user_title { "test enquiry title" }
    end

    factory :project, class: "Investigation::Project" do
      description { "test project" }
      user_title { "test project title" }
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
