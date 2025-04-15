require "rails_helper"

RSpec.describe BulkProductsUpload, :with_flipper, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify do
  subject(:destroy_abandoned_records) { described_class.destroy_abandoned_records! }

  let(:bulk_products_upload_one) { create(:bulk_products_upload) }
  let(:bulk_products_upload_two) { create(:bulk_products_upload, :submitted) }
  let(:bulk_products_upload_three) { create(:bulk_products_upload, updated_at: 10.days.ago) }
  let(:bulk_products_upload_four) { create(:bulk_products_upload, :submitted, updated_at: 10.days.ago) }

  context "with multiple bulk products uploads in different states" do
    before do
      bulk_products_upload_one
      bulk_products_upload_two
      bulk_products_upload_three
      bulk_products_upload_four
    end

    it "deletes records that were last updated more than 3 days ago and have not been submitted" do
      expect { destroy_abandoned_records }.to change(described_class, :count).by(-1)
    end
  end

  describe ".current_bulk_upload_template_path" do
    context "when there are completed product taxonomy imports" do
      let(:draft_import) { create(:product_taxonomy_import, state: "draft") }
      let(:completed_import) { create(:product_taxonomy_import, :with_bulk_upload_template_file, state: "completed") }
      let(:file_uploaded_import) { create(:product_taxonomy_import, state: "file_uploaded") }

      before do
        draft_import
        completed_import
        file_uploaded_import
      end

      context "with the feature flag on" do
        before do
          enable_feature(:new_taxonomy)
        end

        it "returns the bulk upload template file for the latest completed product taxonomy import" do
          expect(described_class.current_bulk_upload_template_path).to start_with("/rails/active_storage/blobs/proxy/")
          expect(described_class.current_bulk_upload_template_path).to end_with("/bulk_upload_template.xlsx")
        end
      end

      context "with the feature flag off" do
        before do
          disable_feature(:new_taxonomy)
        end

        it "returns the fallback path" do
          expect(described_class.current_bulk_upload_template_path).to eq("/files/product_bulk_upload_template.xlsx")
        end
      end
    end

    context "when there are no completed product taxonomy imports" do
      let(:draft_import) { create(:product_taxonomy_import, state: "draft") }
      let(:file_uploaded_import) { create(:product_taxonomy_import, state: "file_uploaded") }

      before do
        draft_import
        file_uploaded_import
      end

      it "returns the fallback path" do
        expect(described_class.current_bulk_upload_template_path).to eq("/files/product_bulk_upload_template.xlsx")
      end
    end

    context "when there are no product taxonomy imports" do
      it "returns the fallback path" do
        expect(described_class.current_bulk_upload_template_path).to eq("/files/product_bulk_upload_template.xlsx")
      end
    end
  end
end
