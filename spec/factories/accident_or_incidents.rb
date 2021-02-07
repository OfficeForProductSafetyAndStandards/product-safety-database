FactoryBot.define do
  factory :accident_or_incident do
    investigation { association :allegation }
    date { "" }
    is_date_known { "no" }
    severity { "serious" }
    usage { "during_normal_use" }
    product { [build(:product)] }
  end
end
