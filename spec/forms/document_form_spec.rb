RSpec.describe DocumentForm, :with_test_queue_adapter do
  subject(:form) { described_class.new(params) }

  let(:title) { Faker::Hipster.word }
  let(:description) { Faker::Lorem.paragraph }
  let(:new_document) { fixture_file_upload(file_fixture("testImage.png")) }
  let(:existing_document) do
    document = ActiveStorage::Blob.create_and_upload!(
      io: new_document,
      filename: new_document.original_filename,
      content_type: new_document.content_type
    )
    document.update!(metadata: { title:, description: })
    document
  end
  let(:document) { new_document }
  let(:existing_document_file_id) { existing_document.signed_id }

  let(:params) do
    {
      title:,
      description:,
      document:,
      existing_document_file_id:
    }
  end

  describe ".from" do
    subject(:form) { described_class.from(existing_document) }

    it "sets the existing_document_file_id attribute" do
      expect(form.existing_document_file_id).to eq(existing_document.signed_id)
    end

    it "sets the title attribute" do
      expect(form.title).to eq(title)
    end

    it "sets the description attribute" do
      expect(form.description).to eq(description)
    end
  end

  describe "validations" do
    let(:existing_document_file_id) { nil }

    before do
      form.cache_file!(create(:user))
    end

    context "with valid attributes" do
      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "with blank title" do
      let(:title) { nil }

      it "is invalid" do
        expect(form).to be_invalid
      end
    end

    context "with blank document" do
      let(:document) { nil }

      context "when existing_document_file_id is supplied" do
        let(:existing_document_file_id) { existing_document.signed_id }

        it "is valid" do
          expect(form).to be_valid
        end
      end

      context "when existing_document_file_id is blank" do
        let(:existing_document_file_id) { nil }

        it "is invalid" do
          expect(form).to be_invalid
        end
      end
    end

    context "with long description" do
      let(:description) { "0" * 10_001 }

      it "is invalid" do
        expect(form).to be_invalid
      end
    end
    # rubocop:disable RSpec/SubjectStub

    context "with large file" do
      it "is invalid" do
        allow(form).to receive(:max_file_byte_size).and_return(1)
        expect(form).to be_invalid
      end
    end
    # rubocop:enable RSpec/SubjectStub
  end

  describe "#initialize" do
    context "when document is not supplied" do
      let(:document) { nil }

      it "populates the document by retrieving it from existing_document_file_id" do
        expect(form.document).to eq(existing_document)
      end
    end
  end

  describe "#cache_file!" do
    let(:existing_document_file_id) { nil }
    let(:user) { instance_double(User, id: "test") }

    context "with a new document" do
      it "creates the blob" do
        expect { form.cache_file!(user) }.to change(ActiveStorage::Blob, :count).by(1)
      end

      it "saves the document filename metadata" do
        form.cache_file!(user)
        expect(form.document.filename).to eq("testImage.png")
      end

      it "saves the document content_type metadata" do
        form.cache_file!(user)
        expect(form.document.content_type).to eq("image/png")
      end

      it "saves the document title metadata" do
        form.cache_file!(user)
        expect(form.document.metadata["title"]).to eq(title)
      end

      it "saves the document description metadata" do
        form.cache_file!(user)
        expect(form.document.metadata["description"]).to eq(description)
      end

      it "saves the document created_by metadata" do
        form.cache_file!(user)
        expect(form.document.metadata["created_by"]).to eq(user.id)
      end

      it "saves the document updated metadata" do
        freeze_time do
          form.cache_file!(user)
          expect(form.document.metadata["updated"].to_json).to eq(Time.zone.now.to_json)
        end
      end

      it "schedules the analyze job" do
        expect { form.cache_file!(user) }.to have_enqueued_job(ActiveStorage::AnalyzeJob)
      end

      it "sets existing_document_file_id" do
        form.cache_file!(user)
        expect(form.existing_document_file_id).to be_a(String)
      end
    end

    context "with an existing document" do
      let(:document) { existing_document }

      it "saves the document title metadata" do
        form.cache_file!(user)
        expect(form.document.metadata["title"]).to eq(title)
      end

      it "saves the document description metadata" do
        form.cache_file!(user)
        expect(form.document.metadata["description"]).to eq(description)
      end

      it "saves the document updated metadata" do
        freeze_time do
          form.cache_file!(user)
          expect(form.document.metadata["updated"].to_json).to eq(Time.zone.now.to_json)
        end
      end
    end
  end
end
