FactoryBot.define do
  trait :with_document_info do
    transient do
      document_file { Rails.root + "test/fixtures/files/test_result.txt" }
      document_title { Faker::Lorem.sentence }
      document_description { Faker::Lorem.paragraph }
      document_has_consumer_info { false }
    end
  end

  trait :with_document do
    with_document_info

    after :create do |model, evaluator|
      file = ActiveSupportHelper.create_file(
        model,
        evaluator,
        metadata: {
          title: evaluator.document_title,
          description: evaluator.document_description,
          updated: Time.now.iso8601
        }
      )

      model.documents.attach(file)
    end
  end

  trait :with_antivirus_checked_document do
    with_document_info

    before :create do |model, evaluator|
      file = ActiveSupportHelper.create_file(
        model,
        evaluator,
        metadata: {
          analyzed: true,
          description: evaluator.document_description,
          identified: true,
          safe: true,
          has_consumer_info: evaluator.document_has_consumer_info,
          created_by: evaluator.owner_id,
          title: evaluator.document_title,
          updated: Time.now.iso8601
        }
      )

      model.documents.attach(file)
    end
  end
end
