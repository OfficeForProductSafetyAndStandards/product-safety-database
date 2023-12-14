require "rails_helper"

RSpec.describe AddDocument, :with_test_queue_adapter do
  let(:investigation) { create(:allegation) }
  let(:product) { create(:product_washing_machine) }
  let(:business) { create(:business) }
  let(:user) { create(:user) }
  let(:parent) { product }

  let(:title) { Faker::Hipster.word }
  let(:description) { Faker::Lorem.paragraph }
  let(:uploaded_document) { fixture_file_upload(file_fixture("testImage.png")) }
  let(:document_metadata) { { "title" => title, "description" => description } }
  let(:document) do
    document = ActiveStorage::Blob.create_and_upload!(
      io: uploaded_document,
      filename: uploaded_document.original_filename,
      content_type: uploaded_document.content_type
    )
    document.update!(metadata: document_metadata)
    document
  end

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(parent:, document:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no document parameter" do
      let(:result) { described_class.call(parent:, user:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no parent parameter" do
      let(:result) { described_class.call(document:, user:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      let(:result) do
        described_class.call(
          user:,
          parent:,
          document:
        )
      end

      %i[investigation product business].each do |parent_name|
        context "when the parent object is a #{parent_name.to_s.upcase_first}" do
          let(:parent) { send(parent_name) }

          it "succeeds" do
            expect(result).to be_a_success
          end

          it "attaches the document to the parent object" do
            expect { result }.to change { parent.documents.count }.by(1)
          end
        end
      end

      context "when the parent is an Investigation" do
        let(:parent) { investigation }

        def expected_email_subject
          "Case updated"
        end

        def expected_email_body(name)
          "Document was attached to the Case by #{name}."
        end

        it "adds an audit activity record", :aggregate_failures do
          result
          last_added_activity = investigation.activities.order(:id).first
          expect(last_added_activity).to be_a(AuditActivity::Document::Add)
          expect(last_added_activity.attachment.blob).to eq(document)
          expect(last_added_activity.metadata).to match(hash_including(document_metadata))
        end

        it_behaves_like "a service which notifies the case owner"
      end
    end
  end
end
