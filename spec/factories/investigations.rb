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
      creator { create(:user, :activated, has_viewed_introduction: true) }
      read_only_teams { [] }
      edit_access_teams { [] }
    end

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

    trait :with_products do
      transient do
        products { [create(:product)] }
      end

      after(:build) do |investigation, options|
        investigation.products = options.products
      end
    end

    trait :restricted do
      is_private { true }
    end

    trait :closed do
      is_closed { true }
    end

    # We need to do this before rather than after create because database
    # constraints on pretty_id need to be satisfied
    before(:create) do |investigation, options|
      CreateCase.call(investigation: investigation, user: options.creator)
    end

    after(:create) do |investigation, evaluator|
      Array.wrap(evaluator.read_only_teams).each do |read_only_team|
        AddTeamToCase.call!(
          investigation: investigation,
          user: investigation.creator_user,
          team: read_only_team,
          collaboration_class: Collaboration::Access::ReadOnly
        )
      end

      Array.wrap(evaluator.edit_access_teams).each do |edit_access_team|
        AddTeamToCase.call!(
          investigation: investigation,
          user: investigation.creator_user,
          team: edit_access_team,
          collaboration_class: Collaboration::Access::Edit
        )
      end
    end
  end
end
