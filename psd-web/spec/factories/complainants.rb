FactoryBot.define do
  factory :complainant do
    name { Faker::Name.name }
    email_address { Faker::Internet.safe_email }
    phone_number { Faker::PhoneNumber.phone_number }
    other_details { Faker::Hipster.paragraphs.join("\n") }
    complainant_type { Complainant::TYPES.keys.sample }
  end
end
