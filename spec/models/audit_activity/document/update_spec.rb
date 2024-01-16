RSpec.describe AuditActivity::Document::Update, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:activity) { described_class.new(metadata: activity_metadata, title:, body: description) }

  let(:file) { fixture_file_upload("testImage.png") }
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: Faker::Hipster.word,
      content_type: "image/png",
      metadata: old_blob_metadata
    )
  end

  let(:old_blob_metadata) do
    { title: old_title, identified: true }
  end

  let(:new_blob_metadata) do
    { title: new_title, identified: true }
  end

  let(:old_title) { Faker::Hipster.word }
  let(:new_title) { "new title" }
  let(:new_description) { "new description" }

  let(:title) { nil }
  let(:description) { nil }

  let(:activity_metadata) { described_class.build_metadata(blob) }

  def change_title
    blob.metadata["title"] = new_title
    blob.save!
  end

  def change_description
    blob.metadata["description"] = new_description
    blob.save!
  end

  describe ".build_metadata" do
    before { change_title }

    it "returns a Hash of changes" do
      expect(activity_metadata.stringify_keys).to eq({
        blob_id: blob.id,
        updates: {
          metadata: [old_blob_metadata, new_blob_metadata]
        }
      }.deep_stringify_keys)
    end
  end

  describe "#title" do
    context "when the title has changed" do
      before { change_title }

      it "returns the title" do
        expect(activity.title(nil)).to eq "Updated: #{new_title} (was: #{old_title})"
      end
    end

    context "when the description has changed" do
      before { change_description }

      it "returns the title" do
        expect(activity.title(nil)).to eq "Updated: Description for #{old_title}"
      end
    end
  end

  describe "#new_description" do
    before { change_description }

    it "returns the new description" do
      expect(activity.new_description).to eq new_description
    end
  end

  describe "#metadata" do
    context "when the object has metadata" do
      it "returns the metadata" do
        expect(activity.metadata).to eq(activity_metadata.stringify_keys)
      end
    end

    context "when the object has no metadata but legacy title showing the title was changed" do
      let(:title) { "Updated: #{new_title} (was: #{old_title})" }
      let(:description) { nil }
      let(:activity_metadata) { nil }
      let(:expected_metadata) do
        {
          blob_id: nil,
          updates: {
            metadata: [
              { title: old_title, description: nil },
              { title: new_title, description: nil }
            ]
          }
        }.deep_stringify_keys
      end

      before { activity.attachment.attach(Rack::Test::UploadedFile.new("test/fixtures/files/test_result.txt")) }

      it "constructs the metadata from the title and attachment" do
        expect(activity.metadata).to eq(expected_metadata)
      end
    end

    context "when the object has no metadata but legacy title showing the description was changed" do
      let(:title) { "Updated: Description for #{old_title})" }
      let(:description) { "test" }
      let(:activity_metadata) { nil }
      let(:expected_metadata) do
        {
          blob_id: nil,
          updates: {
            metadata: [
              { title: nil, description: nil },
              { title: nil, description: }
            ]
          }
        }.deep_stringify_keys
      end

      before { activity.attachment.attach(Rack::Test::UploadedFile.new("test/fixtures/files/test_result.txt")) }

      it "constructs the metadata from the title and attachment" do
        expect(activity.metadata).to eq(expected_metadata)
      end
    end
  end
end
