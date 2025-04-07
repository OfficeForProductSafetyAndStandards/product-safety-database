require "rails_helper"

RSpec.describe ProductTaxonomyImport, :with_stubbed_antivirus do
  # NOTE: Import file validations are tested at the feature level
  subject(:product_taxonomy_import) { create(:product_taxonomy_import, state: "draft") }

  describe "#status" do
    it "returns a human-readable status for the import" do
      expect(product_taxonomy_import.status).to eq("Draft")
    end
  end

  describe "#state" do
    describe "file_uploaded" do
      context "when an import file is attached" do
        it "allows transitioning to the file_uploaded state" do
          expect { product_taxonomy_import.mark_as_file_uploaded! }.to change(product_taxonomy_import, :state).from("draft").to("file_uploaded")
        end
      end

      context "when an import file is not attached" do
        before do
          product_taxonomy_import.import_file.detach
        end

        it "does not allow transitioning to the file_uploaded state" do
          expect { product_taxonomy_import.mark_as_file_uploaded! }.not_to change(product_taxonomy_import, :state)
        end
      end
    end

    describe "database_updated" do
      context "when the database contains product categories and product subcategories from the import" do
        before do
          product_taxonomy_import.update!(state: "file_uploaded")
          create(:product_category, created_at: product_taxonomy_import.created_at + 2.seconds, updated_at: product_taxonomy_import.created_at + 2.seconds)
          create(:product_subcategory, created_at: product_taxonomy_import.created_at + 2.seconds, updated_at: product_taxonomy_import.created_at + 2.seconds)
        end

        it "allows transitioning to the database_updated state" do
          expect { product_taxonomy_import.mark_as_database_updated! }.to change(product_taxonomy_import, :state).from("file_uploaded").to("database_updated")
        end
      end

      context "when the database does not contain product categories and product subcategories from the import" do
        before do
          product_taxonomy_import.update!(state: "file_uploaded")
          create(:product_category, created_at: 1.day.ago, updated_at: 1.day.ago)
          create(:product_subcategory, created_at: 1.day.ago, updated_at: 1.day.ago)
        end

        it "does not allow transitioning to the database_updated state" do
          expect { product_taxonomy_import.mark_as_database_updated! }.not_to change(product_taxonomy_import, :state)
        end
      end
    end

    describe "export_file_created" do
      context "when an export file is attached" do
        subject(:product_taxonomy_import) { create(:product_taxonomy_import, :with_export_file, state: "database_updated") }

        it "allows transitioning to the export_file_created state" do
          expect { product_taxonomy_import.mark_as_export_file_created! }.to change(product_taxonomy_import, :state).from("database_updated").to("export_file_created")
        end
      end

      context "when an export file is not attached" do
        before do
          product_taxonomy_import.update!(state: "database_updated")
        end

        it "does not allow transitioning to the export_file_created state" do
          expect { product_taxonomy_import.mark_as_export_file_created! }.not_to change(product_taxonomy_import, :state)
        end
      end
    end

    describe "bulk_upload_template_created" do
      context "when a bulk upload template file is attached" do
        subject(:product_taxonomy_import) { create(:product_taxonomy_import, :with_bulk_upload_template_file, state: "export_file_created") }

        it "allows transitioning to the bulk_upload_template_created state" do
          expect { product_taxonomy_import.mark_as_bulk_upload_template_created! }.to change(product_taxonomy_import, :state).from("export_file_created").to("bulk_upload_template_created")
        end
      end

      context "when a bulk upload template file is not attached" do
        before do
          product_taxonomy_import.update!(state: "export_file_created")
        end

        it "does not allow transitioning to the bulk_upload_template_created state" do
          expect { product_taxonomy_import.mark_as_bulk_upload_template_created! }.not_to change(product_taxonomy_import, :state)
        end
      end
    end

    describe "completed" do
      context "when the product taxonomy import is in the bulk_upload_template_created state" do
        before do
          product_taxonomy_import.update!(state: "bulk_upload_template_created")
        end

        it "allows transitioning to the completed state" do
          expect { product_taxonomy_import.mark_as_completed! }.to change(product_taxonomy_import, :state).from("bulk_upload_template_created").to("completed")
        end
      end
    end
  end
end
