require "rails_helper"

RSpec.describe TestResultForm, :with_stubbed_elasticsearch, :with_stubbed_mailer, type: :model do
  subject(:form) { described_class.new(params) }

  let(:document) { Rack::Test::UploadedFile.new("test/fixtures/files/test_result.txt") }
  let(:document_description) { Faker::Hipster.sentence }
  let(:date) { { day: "1", month: "1", year: "2020" } }
  let(:params) do
    attributes_for(:test_result).except(:documents, :date).tap do |attributes|
      attributes[:document] = { file: document, description: document_description }
      attributes[:date] = date
    end
  end

  let(:investigation) { params.delete(:investigation) }

  before { investigation }

  describe ".from", :with_stubbed_antivirus do
    let(:test_result) { create(:test_result) }
    let(:expected_attributes) do
      test_result
        .serializable_hash(only: described_class::ATTRIBUTES_FROM_TEST_RESULT)
        .merge(existing_document_file_id: test_result.document.signed_id)
    end

    it "serialises the active record object to a form correctly", :aggregate_failures do
      form = described_class.from(test_result)
      expect(form).to have_attributes(expected_attributes)
    end
  end

  describe "validations" do
    it { is_expected.to validate_length_of(:details).is_at_most(50_000) }
    it { is_expected.to validate_inclusion_of(:legislation).in_array(Rails.application.config.legislation_constants["legislation"]).with_message("Select the legislation that relates to this test") }
    it { is_expected.to validate_inclusion_of(:result).in_array(Test::Result.results.keys).with_message("Select result of the test") }
    it { is_expected.to validate_presence_of(:document).with_message("Provide the test results file") }
    it { is_expected.to validate_presence_of(:product_id).with_message("Select the product which was tested").on(:create_with_product) }

    it_behaves_like "it does not allow dates in the future", :date
    it_behaves_like "it does not allow malformed dates", :date
    it_behaves_like "it does not allow an incomplete", :date
  end

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
