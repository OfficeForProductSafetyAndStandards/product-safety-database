FactoryBot.define do
  factory :contact do
    association :business, factory: :business
    job_title { "Director" }
    name { "Mr John Doe" }
    email { "john@example.com" }
    phone_number { "07700 900000" }
  end
end
