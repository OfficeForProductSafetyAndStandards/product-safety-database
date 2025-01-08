FactoryBot.define do
  trait :with_document_info do
    transient do
      document_file { Rails.root.join("test/fixtures/files/test_result.txt") }
      document_title { Faker::Lorem.sentence }
      document_description { Faker::Lorem.paragraph }
    end
  end

  trait :with_image_info do
    transient do
      document_file { Rails.root.join("test/fixtures/files/testImage.png") }
      document_title { Faker::Lorem.sentence }
      document_description { Faker::Lorem.paragraph }
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
          updated: Time.zone.now.iso8601
        }
      )

      if model.respond_to?(:document)
        model.document.attach(file)
      elsif model.respond_to?(:attachment)
        model.attachment.attach(file)
      else
        model.documents.attach(file)
      end
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
          created_by: evaluator.owner_id,
          title: evaluator.document_title,
          updated: Time.zone.now.iso8601
        }
      )

      if model.respond_to?(:document)
        model.document.attach(file)
      else
        model.documents.attach(file)
      end
    end
  end

  trait :with_antivirus_checked_image do
    with_image_info

    before :create do |model, evaluator|
      file = ActiveSupportHelper.create_file(
        model,
        evaluator,
        metadata: {
          analyzed: true,
          description: evaluator.document_description,
          identified: true,
          safe: true,
          created_by: evaluator.owner_id,
          title: evaluator.document_title,
          updated: Time.zone.now.iso8601
        }
      )

      if model.respond_to?(:document)
        model.document.attach(file)
      else
        model.documents.attach(file)
      end
    end
  end
end
