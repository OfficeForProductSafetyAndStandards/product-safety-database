FactoryBot.define do
  trait :with_document do
    transient do
      document_file { Rails.root + "test/fixtures/files/test_result.txt" }
      document_title { Faker::Lorem.sentence }
      document_description { Faker::Lorem.paragraph }
    end

    after :create do |model, evaluator|
      file = ActiveStorage::Blob.create_after_upload!(io: File.open(evaluator.document_file), filename: File.basename(evaluator.document_file), content_type: "text/plain", metadata: {
        title: evaluator.document_title,
        description: evaluator.document_description,
        updated: Time.now.iso8601
      })

      model.documents.attach(file)
    end
  end
end
