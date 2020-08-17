FactoryBot.define do
  factory :risk_assessment do
    investigation { association :allegation }
    assessed_on { "2020-07-20" }
    risk_level { "" }
    assessed_by_team { association :team }
    assessed_by_business { nil }
    assessed_by_other { nil }
    details { "MyText" }
    products { [build(:product)] }
    added_by_user { association :user }
    added_by_team { association :team }
  end
end
