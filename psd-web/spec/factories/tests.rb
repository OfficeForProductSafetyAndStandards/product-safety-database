FactoryBot.define do
  factory :test do
    date_day    { date.day }
    date_month  { date.month }
    date_year   { date.year }
    details     { Faker::Hipster.sentence }
    legislation { Rails.application.config.legislation_constants["legislation"].sample }

    transient { date { Faker::Date.backward(days: 14) } }
  end

  factory :test_result, class: "Test::Result", parent: :test do
    result { Test::Result.results[:passed] }

    after(:build) do |test|
      test.documents.attach(
        io: File.open(Rails.root + "test/fixtures/files/test_result.txt"),
        filename: "test result"
      )
    end
  end

  factory :test_request, class: "Test::Request", parent: :test do
    after(:build) do |test|
      test.documents.attach(
        io: File.open(Rails.root + "test/fixtures/files/test_result.txt"),
        filename: "test request"
      )
    end
  end
end
