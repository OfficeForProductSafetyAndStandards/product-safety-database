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

    transient do
      owner { nil }

      after(:create) do |investigation, evaluator|
        if evaluator.owner.nil?
          create(:case_creator, investigation: investigation)
        else
          create(:case_creator, investigation: investigation, collaborating: evaluator.owner)
        end
        investigation.reload
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

  factory :allegation, class: "Investigation::Allegation", parent: :investigation do
    description { "test allegation" }
    user_title { "test allegation title" }
  end

  factory :enquiry, class: "Investigation::Enquiry", parent: :investigation do
    description { "test enquiry" }
    user_title { "test enquiry title" }
  end

  factory :project, class: "Investigation::Project", parent: :investigation do
    description { "test project" }
    user_title { "test project title" }
  end
end
