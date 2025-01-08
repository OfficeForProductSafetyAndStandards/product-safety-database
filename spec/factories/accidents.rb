FactoryBot.define do
  factory :accident do
    investigation { association :allegation }
    date { "" }
    is_date_known { "no" }
    severity { "serious" }
    usage { "during_normal_use" }
    investigation_product
  end
end
