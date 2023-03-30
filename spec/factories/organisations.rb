FactoryBot.define do
  factory :organisation do
    name { "test organisation" }

    trait :internal_opss_team do
      internal_opss_team { true }
    end

    trait :external_regulator do
      external_regulator { true }
      regulator
    end

    trait :local_authority do
      local_authority { true }
      ts_region
    end
  end
end
