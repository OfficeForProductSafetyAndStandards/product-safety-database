# spec/factories/active_storage.rb

# Usage
# Create a blob record without actual file content
# create(:active_storage_blob)

# Create a blob record and upload file content
# create(:active_storage_blob, :with_file)

# Create a blob with custom content
# create(:active_storage_blob, :with_file, file_content: "Custom content")

FactoryBot.define do
  factory :active_storage_blob, class: "ActiveStorage::Blob" do
    filename { "test_file.txt" }
    byte_size { 1024 }
    content_type { "text/plain" }

    transient do
      file_content { "Hello, World!" }
    end

    checksum { Digest::MD5.base64digest(file_content) }

    trait :with_file do
      after(:create) do |blob, evaluator|
        blob.service.upload(blob.key, StringIO.new(evaluator.file_content))
      end
    end
  end
end
