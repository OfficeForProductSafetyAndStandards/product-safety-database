FactoryBot.define do
  factory :test do
    date_day    { date.day }
    date_month  { date.month }
    date_year   { date.year }
    details     { Faker::Hipster.sentence }
    legislation { Rails.application.config.legislation_constants["legislation"].sample }

    documents { [Rack::Test::UploadedFile.new("test/fixtures/files/test_result.txt")] }

    transient do
      date { Faker::Date.backward(days: 14) }
    end
  end

  factory :test_result, class: "Test::Result", parent: :test do
    result { Test::Result.results[:passed] }
  end

  factory :test_request, class: "Test::Request", parent: :test do
  end
end
