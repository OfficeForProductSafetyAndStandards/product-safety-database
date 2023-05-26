FactoryBot.define do
  factory :correspondence do
    overview { Faker::Lorem.sentence }
    details { Faker::Lorem.paragraph }
    correspondent_name { Faker::Name.name }
    email_address { Faker::Internet.email }
    email_subject { Faker::Lorem.sentence }
    email_direction { Correspondence::Email.email_directions[:inbound] }
    phone_number { Faker::PhoneNumber.phone_number }
    contact_method { %w[phone email].sample }

    transient do
      correspondence_file { Rails.root.join("test/fixtures/files/test_result.txt") }
    end
  end

  factory :correspondence_meeting, class: "Correspondence::Meeting", parent: :correspondence do
    correspondence_date_day { correspondence_date.day }
    correspondence_date_month { correspondence_date.month }
    correspondence_date_year { correspondence_date.year }

    transient do
      correspondence_date { Faker::Date.backward(days: 14) }
    end

    after(:build) do |correspondence, evaluator|
      correspondence.transcript.attach(
        io: File.open(evaluator.correspondence_file),
        filename: "meeting correspondence"
      )
    end
  end

  factory :correspondence_phone_call, class: "Correspondence::PhoneCall", parent: :correspondence do
    correspondence_date { Faker::Date.backward(days: 14) }

    after(:build) do |correspondence, evaluator|
      correspondence.transcript.attach(
        io: File.open(evaluator.correspondence_file),
        filename: "phone call correspondence"
      )
    end
  end
end
