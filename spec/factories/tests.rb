FactoryBot.define do
  factory :test do
    date        { 14.days.ago.to_date }
    details     { Faker::Hipster.sentence }
    legislation { Rails.application.config.legislation_constants["legislation"].sample }
    product
    investigation { create(:allegation) }

    document { Rack::Test::UploadedFile.new("test/fixtures/files/test_result.txt") }
  end

  factory :test_result, class: "Test::Result", parent: :test do
    result { Test::Result.results[:passed] }
    standards_product_was_tested_against { [] }
  end

  factory :test_request, class: "Test::Request", parent: :test do
  end
end
