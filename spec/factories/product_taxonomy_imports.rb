FactoryBot.define do
  factory :product_taxonomy_import do
    association :user

    state { "file_uploaded" }

    after(:build) do |model, _evaluator|
      model.import_file.attach(
        io: File.open(Rails.root.join("test/fixtures/files/taxonomy.xlsx")),
        filename: "taxonomy.xlsx",
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )
    end

    trait :with_export_file do
      after(:build) do |model, _evaluator|
        model.export_file.attach(
          io: File.open(Rails.root.join("test/fixtures/files/taxonomy_export.xlsx")),
          filename: "taxonomy_export.xlsx",
          content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
      end
    end

    trait :with_bulk_upload_template_file do
      after(:build) do |model, _evaluator|
        model.bulk_upload_template_file.attach(
          io: File.open(Rails.root.join("test/fixtures/files/bulk_upload_template.xlsx")),
          filename: "bulk_upload_template.xlsx",
          content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
      end
    end
  end
end
