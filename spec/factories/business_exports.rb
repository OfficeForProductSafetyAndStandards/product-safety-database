FactoryBot.define do
  factory :business_export do
    user

    after(:build) do |business_export|
      business_export.export_file.attach(
        io: StringIO.new("Dummy content of the file, perhaps mimicking an XLSX structure."),
        filename: "dummy_export.xlsx",
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )
    end
  end
end
