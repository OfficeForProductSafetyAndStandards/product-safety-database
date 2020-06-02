FactoryBot.define do
  factory :test do
    date_day    { date.day }
    date_month  { date.month }
    date_year   { date.year }
    details     { Faker::Hipster.sentence }
    legislation { Rails.application.config.legislation_constants["legislation"].sample }

    transient {
      date { Faker::Date.backward(days: 14) }
      test_file { Rails.root + "test/fixtures/files/test_result.txt" }
    }
  end

  factory :test_result, class: "Test::Result", parent: :test do
    result { Test::Result.results[:passed] }

    after(:build) do |test, evaluator|
      test.documents.attach(
        io: File.open(evaluator.test_file),
        filename: "test result"
      )
    end
  end

  factory :test_request, class: "Test::Request", parent: :test do
    after(:build) do |test, evaluator|
      test.documents.attach(
        io: File.open(evaluator.test_file),
        filename: "test request"
      )
    end
  end
end
