FactoryBot.define do
  factory :ucr_number do
    association :investigation, factory: :allegation
    number { Faker::Alphanumeric.alphanumeric(number: 16) }
  end
end
