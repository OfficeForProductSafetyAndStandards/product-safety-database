# spec/factories/active_storage.rb

FactoryBot.define do
  factory :active_storage_blob, class: "ActiveStorage::Blob" do
    filename { "test_file.txt" }
    byte_size { 1024 }
    checksum { Digest::MD5.base64digest("Hello, World!") }
    content_type { "text/plain" }

    trait :with_file do
      after(:create) do |blob|
        blob.service.upload(blob.key, StringIO.new("Hello, World!"))
      end
    end
  end
end
