FactoryBot.define do
  factory :complainant do
    email_address { Faker::Internet.email(domain: "example") }
    name { Faker::Name.name }
    other_details { Faker::Lorem.paragraph }
    phone_number { Faker::PhoneNumber.phone_number }
    complainant_type { Complainant::TYPES.keys.sample }
    association :investigation, factory: :allegation
  end

  Complainant::TYPES.each_key do |type|
    factory :"complainant_#{type}", parent: :complainant do
      complainant_type { type }
    end
  end
end
