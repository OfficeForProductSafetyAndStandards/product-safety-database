FactoryBot.define do
  factory :risk_assessment do
    investigation_id { 1 }
    assessed_on { "2020-07-20" }
    risk_level { "" }
    completed_by_team_id { "MyText" }
    completed_by_business_id { 1 }
    completed_by_other { "MyText" }
    details { "MyText" }
    added_by_user_id { "MyText" }
    added_by_team_id { "MyText" }
  end
end
