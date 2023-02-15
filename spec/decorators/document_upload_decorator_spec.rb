require "rails_helper"

RSpec.describe DocumentUploadDecorator, :with_stubbed_opensearch do
  subject(:decorated_document_upload) { product.document_uploads.first.decorate }

  let(:product) { create(:product, :with_antivirus_checked_image_document_upload) }

  describe "#title" do
    specify { expect(decorated_document_upload.title).to eq(product.document_uploads.first.metadata["title"]) }
  end

  describe "#description" do
    specify { expect(decorated_document_upload.description).to eq(product.document_uploads.first.metadata["description"]) }
  end

  describe "#event_type" do
    specify { expect(decorated_document_upload.event_type).to eq("PNG") }
  end
end
