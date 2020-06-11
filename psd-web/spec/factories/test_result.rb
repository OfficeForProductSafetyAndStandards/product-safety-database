FactoryBot.define do
  factory :test_result, class: "Test::Result" do
    date { Date.parse("2019-01-02") }

    # required by existing validations:
    date_day { date.day }
    date_month { date.month }
    date_year { date.year }

    documents { [Rack::Test::UploadedFile.new("test/fixtures/files/test_result.txt")] }
  end
end
