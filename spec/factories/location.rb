FactoryBot.define do
  factory :location do
    association :business

    name { "Registered office" }
    address_line_1 { Faker::Address.street_address }
    address_line_2 { Faker::Address.community }
    city { Faker::Address.city }
    country { Faker::Address.country }
    county { Faker::Address.state }
    phone_number { Faker::PhoneNumber.phone_number }
    postal_code { Faker::Address.postcode }
  end
end
