require "rails_helper"

RSpec.describe TestResultForm, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:form) { described_class.new(params) }

  let(:document) { Rack::Test::UploadedFile.new("test/fixtures/files/test_result.txt") }
  let(:document_description) { Faker::Hipster.sentence }
  let(:params) do
    attributes_for(:test_result).except(:documents).tap do |attributes|
      attributes[:document] = { file: document, description: document_description }
    end
  end

  let(:investigation) { params.delete(:investigation) }

  before { investigation }

  describe "#cache_files" do
    it "chaches the documents files" do
      expect { form.cache_file! }.to change { ActiveStorage::Blob.count }.by(1)
    end

    it "stores the blob signed id" do
      expect { form.cache_file! }.to change(form, :existing_document_file_id).from(nil).to(instance_of(String))
    end
  end

  describe "#load_documents_files" do
    context "when a file was previously cached" do
      let(:previous_form) { described_class.new(params) }

      before { previous_form.cache_file! }

      context "when no document is uploaded" do
        before { params[:document].delete(:file) }

        it "does not load the document file" do
          expect { form.load_document_file }.not_to change(form, :document)
        end

        context "when no new document has been uploaded" do
          before { params[:existing_document_file_id] = previous_form.existing_document_file_id }

          it "loads the previously cached document" do
            expect { form.load_document_file }
              .to change(form, :document).from(nil).to(instance_of(ActiveStorage::Blob))
          end
        end
      end
    end
  end
end
