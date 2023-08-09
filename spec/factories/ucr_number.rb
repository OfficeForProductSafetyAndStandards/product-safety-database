FactoryBot.define do
  factory :ucr_number do
    association :investigation_product
    number { Faker::Alphanumeric.alphanumeric(number: 16) }
  end
end
