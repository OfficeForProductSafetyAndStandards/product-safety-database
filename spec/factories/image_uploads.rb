FactoryBot.define do
  factory :image_upload do
    association :upload_model, factory: :notification

    after(:build) do |image_upload|
      file = ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("test/fixtures/files/testImage.png")),
        filename: "testImage.png",
        content_type: "image/png"
      )
      file.analyze_later
      image_upload.file_upload.attach(file)
    end
  end

  trait :with_image_upload_info do
    transient do
      document_file { Rails.root.join("test/fixtures/files/testImage.png") }
    end
  end

  trait :with_antivirus_checked_image_upload do
    with_image_upload_info

    after :create do |model, evaluator|
      file = ActiveSupportHelper.create_file(
        model,
        evaluator,
        content_type: "image/png",
        metadata: {
          analyzed: true,
          identified: true,
          safe: true
        }
      )

      image_upload = ImageUpload.create!(
        upload_model: model,
        file_upload: file
      )

      model.update!(image_upload_ids: [image_upload.id])
    end
  end

  # This trait is used to create an image upload independently of a model
  trait :with_antivirus_safe_image_upload do
    with_image_upload_info
    after(:create) do |image_upload|
      file = ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("test/fixtures/files/testImage.png")),
        filename: "testImage.png",
        content_type: "image/png"
      )

      image_upload.file_upload.attach(file)
      image_upload.file_upload.metadata = { "safe" => true }
      image_upload.file_upload.save!
    end
  end

  trait :with_virus_image_upload do
    with_image_upload_info
    after(:create) do |image_upload|
      file = ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("test/fixtures/files/testImage.png")),
        filename: "testImage.png",
        content_type: "image/png"
      )

      image_upload.file_upload.attach(file)
      image_upload.file_upload.metadata = { "safe" => false }
      image_upload.file_upload.save!
    end
  end
end
