require "rails_helper"

RSpec.describe UpdateDocument, :with_test_queue_adapter do
  let(:investigation) { create(:allegation) }
  let(:product) { create(:product_washing_machine) }
  let(:business) { create(:business) }
  let(:user) { create(:user) }
  let(:parent) { product }

  let(:old_title) { "old title" }
  let(:old_description) { "old description" }
  let(:new_title) { Faker::Hipster.word }
  let(:new_description) { Faker::Lorem.paragraph }
  let(:old_document_metadata) { { "title" => old_title, "description" => old_description, "updated" => "test" } }
  let(:new_document_metadata) { { "title" => new_title, "description" => new_description } }
  let(:uploaded_document) do
    uploaded_document = fixture_file_upload(file_fixture("testImage.png"))
    document = ActiveStorage::Blob.create_and_upload!(
      io: uploaded_document,
      filename: uploaded_document.original_filename,
      content_type: uploaded_document.content_type
    )
    document.update!(metadata: old_document_metadata)
    document
  end

  let(:file) { parent.documents.first.blob }

  before do
    AddDocument.call!(parent:, document: uploaded_document, user:)
  end

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(parent:, file:) }

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
      let(:result) { described_class.call(file:, user:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      context "with no changes" do
        let(:result) do
          described_class.call(
            user:,
            parent:,
            file:,
            title: old_title,
            description: old_description
          )
        end

        %i[investigation product business].each do |parent_name|
          context "when the parent object is a #{parent_name.to_s.upcase_first}" do
            let(:parent) { send(parent_name) }

            it "succeeds" do
              expect(result).to be_a_success
            end

            it "does not update the file" do
              expect { result }.not_to change(file, :metadata)
            end
          end
        end

        context "when the parent is an Investigation" do
          let(:parent) { investigation }

          it "does not add an audit activity record" do
            expect { result }.not_to change { investigation.activities.count }
          end

          it "does not send a notification email" do
            expect { result }.not_to have_enqueued_mail(NotifyMailer, :investigation_updated)
          end
        end
      end

      context "with changes" do
        let(:result) do
          described_class.call(
            user:,
            parent:,
            file:,
            title: new_title,
            description: new_description
          )
        end

        %i[investigation product business].each do |parent_name|
          context "when the parent object is a #{parent_name.to_s.upcase_first}" do
            let(:parent) { send(parent_name) }

            it "succeeds" do
              expect(result).to be_a_success
            end

            it "updates the file title metadata" do
              result
              expect(file.metadata["title"]).to eq(new_title)
            end

            it "updates the file description metadata" do
              result
              expect(file.metadata["description"]).to eq(new_description)
            end

            it "updates the file updated metadata" do
              freeze_time do
                result
                expect(file.metadata["updated"].to_json).to eq(Time.zone.now.to_json)
              end
            end
          end
        end

        context "when the parent is an Investigation" do
          let(:parent) { investigation }
          let(:last_added_activity) { investigation.activities.order(:id).first }

          def expected_email_subject
            "Case updated"
          end

          def expected_email_body(name)
            "Document attached to the Case was updated by #{name}."
          end

          it "adds an audit activity record", :aggregate_failures do
            result
            expect(last_added_activity).to be_a(AuditActivity::Document::Update)
            expect(last_added_activity.attachment.blob).to eq(uploaded_document)
            expect(last_added_activity.metadata).to match({
              "blob_id" => file.id,
              "updates" => { "metadata" => [hash_including(old_document_metadata), hash_including(new_document_metadata)] }
            })
          end

          it_behaves_like "a service which notifies the case owner"
        end
      end
    end
  end
end
