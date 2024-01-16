RSpec.describe AuditActivity::Document::Destroy, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:activity) { described_class.new(metadata:, title:, body: description) }

  let(:blob) { instance_double(ActiveStorage::Blob, id: 1, metadata: { title: "test", description: "test", created_by: "123" }) }
  let(:metadata) { described_class.build_metadata(blob) }
  let(:title) { nil }
  let(:description) { nil }

  describe ".build_metadata" do
    it "returns a Hash of attributes" do
      expect(metadata).to eq({
        blob_id: blob.id,
        title: blob.metadata[:title],
        description: blob.metadata[:description],
        created_by: "123"
      })
    end
  end

  describe "#title" do
    it "returns the title" do
      expect(activity.title(nil)).to eq "Deleted: #{blob.metadata[:title]}"
    end
  end

  describe "#metadata" do
    context "when the object has metadata" do
      it "returns the metadata" do
        expect(activity.metadata).to eq(metadata.stringify_keys)
      end
    end

    context "when the object has no metadata" do
      let(:metadata) { nil }
      let(:expected_metadata) do
        { "identified" => true, "blob_id" => nil }
      end

      before { activity.attachment.attach(Rack::Test::UploadedFile.new("test/fixtures/files/test_result.txt")) }

      it "constructs the metadata from the attachment blob" do
        expect(activity.metadata).to eq(expected_metadata)
      end
    end
  end
end
