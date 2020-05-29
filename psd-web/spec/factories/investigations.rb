FactoryBot.define do
  factory :investigation do
    user_title { "investigation title" }
    complainant_reference { "complainant reference" }
    date_received { 1.day.ago }
    received_type { %w[email phone other].sample }
    is_closed { false }
    coronavirus_related { false }
    reported_reason       {}
    hazard_type           {}
    hazard_description    {}
    non_compliant_reason  {}
    description { "Investigation into product" }

    association :owner, factory: :user

    factory :allegation, class: "Investigation::Allegation" do
      description { "test allegation" }
      user_title { "test allegation title" }

      factory :allegation_unsafe, class: "Investigation::Allegation" do
        reported_unsafe
      end
    end

    factory :enquiry, class: "Investigation::Enquiry" do
      description { "test enquiry" }
      user_title { "test enquiry title" }
    end

    factory :project, class: "Investigation::Project" do
      description { "test project" }
      user_title { "test project title" }
    end

    trait :with_complainant do
      association :complainant
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

    trait :reported_safe do
      after(:build) do |investigation|
        WhyReportingForm.new(reported_reason_safe_and_compliant: true)
          .assign_to(investigation)
      end
    end

    trait :reported_unsafe do
      after(:build) do |investigation|
        WhyReportingForm.new(
          reported_reason_unsafe: true,
          hazard_type: Rails.application.config.hazard_constants["hazard_type"].sample,
          hazard_description: Faker::Hipster.sentence,
        ).assign_to(investigation)
      end
    end

    trait :reported_unsafe_and_non_compliant do
      after(:build) do |investigation|
        WhyReportingForm.new(
          reported_reason_unsafe: true,
          hazard_type: Rails.application.config.hazard_constants["hazard_type"].sample,
          hazard_description: Faker::Hipster.sentence,
          non_compliant_reason: Faker::Hipster.sentence,
          reported_reason_non_compliant: true
        ).assign_to(investigation)
      end
    end
  end
end
