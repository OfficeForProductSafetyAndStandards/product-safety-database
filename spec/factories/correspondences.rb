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
