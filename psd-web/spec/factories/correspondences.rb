FactoryBot.define do
  factory :correspondence do
    overview { Faker::Lorem.sentence }
    details { Faker::Lorem.paragraph }
    correspondent_name { Faker::Name.name }
    email_address { Faker::Internet.safe_email }
    email_subject { Faker::Lorem.sentence }
    email_direction { "from" }
    phone_number { Faker::PhoneNumber.phone_number }
    correspondence_date_day { correspondence_date.day }
    correspondence_date_month { correspondence_date.month }
    correspondence_date_year { correspondence_date.year }
    contact_method { %w[phone email].sample }

    transient do
      correspondence_date { Faker::Date.backward(days: 14) }
    end
  end
end
