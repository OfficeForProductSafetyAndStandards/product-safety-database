FactoryBot.define do
  factory :investigation_product do
    association :investigation, factory: :allegation
    association :product

    trait :with_ucr_numbers do
      transient do
        ucr_numbers { [create(:ucr_number)] }
      end

      after(:build) do |investigation, options|
        investigation.ucr_numbers = options.ucr_numbers
      end
    end
  end
end
