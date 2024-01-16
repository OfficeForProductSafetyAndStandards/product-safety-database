RSpec.describe DocumentUploadDecorator, :with_stubbed_opensearch do
  subject(:decorated_document_upload) { product.document_uploads.first.decorate }

  let(:product) { create(:product, :with_antivirus_checked_image_document_upload) }

  describe "#title" do
    context "when the base document upload has a title" do
      it "returns the title" do
        expect(decorated_document_upload.title).to eq(product.document_uploads.first.title)
      end
    end

    context "when the base document upload does not have a title" do
      before do
        product.document_uploads.first.update_attribute(:title, nil) # rubocop:disable Rails/SkipsModelValidations
      end

      it "returns the filename" do
        expect(decorated_document_upload.title).to eq(product.document_uploads.first.file_upload.filename.to_s)
      end
    end
  end

  describe "#event_type" do
    specify { expect(decorated_document_upload.event_type).to eq("PNG") }
  end
end
