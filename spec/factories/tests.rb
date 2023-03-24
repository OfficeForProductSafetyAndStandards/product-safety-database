FactoryBot.define do
  factory :test do
    date        { 14.days.ago.to_date }
    details     { Faker::Hipster.sentence }
    legislation { Rails.application.config.legislation_constants["legislation"].sample }
    investigation_product
    investigation { create(:allegation) }

    document { Rack::Test::UploadedFile.new("test/fixtures/files/test_result.txt") }
    after(:create) do |test_result|
      test_result.document_blob.metadata["description"] = Faker::Hipster.sentence
      test_result.document_blob.save!
    end
  end

  factory :test_result, class: "Test::Result", parent: :test do
    result { Test::Result.results.keys.sample }
    standards_product_was_tested_against { %w[Test] }
  end

  factory :test_request, class: "Test::Request", parent: :test do
  end
end
