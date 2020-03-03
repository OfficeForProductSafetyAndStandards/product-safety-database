def create_file(_model, evaluator, metadata: {})
  ActiveStorage::Blob.create_after_upload!(
    io: File.open(evaluator.document_file),
    filename: File.basename(evaluator.document_file),
    content_type: "text/plain",
    metadata: metadata
  )
end

FactoryBot.define do
  trait :with_document_info do
    transient do
      document_file { Rails.root + "test/fixtures/files/test_result.txt" }
      document_title { Faker::Lorem.sentence }
      document_description { Faker::Lorem.paragraph }
    end
  end

  trait :with_document do
    with_document_info

    after :create do |model, evaluator|
      file = create_file(model, evaluator, metadata: {
                         title: evaluator.document_title,
                         description: evaluator.document_description,
                         updated: Time.now.iso8601
                        })

      model.documents.attach(file)
    end
  end

  trait :with_antivirus_checked_document do
    with_document_info

    after :create do |model, evaluator|
      file = create_file(model, evaluator, metadata: {
                         analyzed: true,
                         description: evaluator.document_description,
                         identified: true,
                         safe: true,
                         title: evaluator.document_title,
                         updated: Time.now.iso8601
                        })

      model.documents.attach(file)
    end
  end
end
