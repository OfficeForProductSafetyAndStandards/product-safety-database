require "rails_helper"
require Rails.root.join("db/migrate/20230215114714_migrate_documents_to_document_uploads_for_products.rb")

RSpec.describe MigrateDocumentsToDocumentUploadsForProducts, :with_stubbed_opensearch, :with_stubbed_antivirus do
  let(:migration_context) { ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths) }
  let(:previous_version) { 20_230_215_102_554 }
  let(:current_version) { 20_230_215_114_714 }
  let(:up) do
    ActiveRecord::Migration.suppress_messages do
      migration_context.up(current_version)
    end
  end
  let(:down) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.disable_ddl_transaction do
        migration_context.down(previous_version)
      end
    end
  end

  describe "#up" do
    before do
      down
      all_products
      up
    end

    context "when there are no records to migrate" do
      let(:products) { create_list(:product, 3, :with_document_upload) }
      let(:all_products) { products }

      it "doesn't change any records" do
        all_products.each do |product|
          document_upload = DocumentUpload.find_by(upload_model_id: product.reload.id)
          expect(product.document_uploads.count).to eq(1)
          expect(product.document_upload_ids).to eq([document_upload.id])
          expect(document_upload.file_upload.record).to eq(document_upload)
          expect(document_upload.file_upload.blob.metadata).to match(
            "analyzed" => true,
            "identified" => true,
            "safe" => true
          )
        end
      end
    end

    context "when there are records to migrate" do
      let(:products) { create_list(:product, 3, :with_document) }
      let(:new_products) { create_list(:product, 2, :with_document_upload) }
      let(:all_products) { (products + new_products) }

      it "changes the relevant records" do
        all_products.each do |product|
          document_upload = DocumentUpload.find_by(upload_model_id: product.reload.id).reload
          expect(product.document_uploads.count).to eq(1)
          expect(product.document_upload_ids).to eq([document_upload.id])
          expect(document_upload.file_upload.record).to eq(document_upload)
          expect(document_upload.file_upload.blob.metadata).to match(
            "analyzed" => true,
            "identified" => true,
            "safe" => true
          )
        end
      end
    end
  end

  describe "#down" do
    before do
      all_products
      down
    end

    after do
      up
    end

    context "when there are no records to migrate" do
      let(:products) { create_list(:product, 3, :with_document) }
      let(:all_products) { products }

      it "doesn't change any records" do
        all_products.each do |product|
          document = ActiveStorage::Attachment.find_by(record_id: product.reload.id)
          expect(product.document_uploads.count).to eq(0)
          expect(product.document_upload_ids).to eq([])
          expect(document.record).to eq(product)
          expect(document.metadata).to match(a_hash_including(
                                               "analyzed" => true,
                                               "identified" => true,
                                               "safe" => true,
                                               "title" => String,
                                               "description" => String
                                             ))
        end
      end
    end

    context "when there are records to migrate" do
      let(:products) { create_list(:product, 3, :with_document_upload) }
      let(:old_products) { create_list(:product, 2, :with_document) }
      let(:all_products) { products }

      it "changes the relevant records" do
        all_products.each do |product|
          document = ActiveStorage::Attachment.find_by(record_id: product.reload.id)
          expect(product.document_uploads.count).to eq(0)
          expect(product.document_upload_ids).to eq([])
          expect(document.record).to eq(product)
          expect(document.metadata).to match(a_hash_including(
                                               "analyzed" => true,
                                               "identified" => true,
                                               "safe" => true,
                                               "title" => String,
                                               "description" => String
                                             ))
        end
      end
    end
  end
end
