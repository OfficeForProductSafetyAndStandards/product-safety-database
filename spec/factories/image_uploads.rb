FactoryBot.define do
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
end
