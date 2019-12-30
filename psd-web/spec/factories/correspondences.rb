FactoryBot.define do
  factory :correspondence do
    overview { Faker::Lorem.sentence }
    details { Faker::Lorem.paragraph }
    correspondent_name { Faker::Name.name }
    email_address { Faker::Internet.email(domain: "example") }
    email_subject { Faker::Lorem.sentence }
    email_direction { "from" }
    phone_number { Faker::PhoneNumber.phone_number }
    correspondence_date_day { Faker::Date.backward(days: 14).day }
    correspondence_date_month { Faker::Date.backward(days: 14).month }
    correspondence_date_year { Faker::Date.backward(days: 14).year }
    contact_method { %w[phone email].sample }
  end
end
