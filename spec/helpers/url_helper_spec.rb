require "rails_helper"

RSpec.describe UrlHelper do
  describe "#path_for_model", :with_stubbed_opensearch, :with_stubbed_mailer do
    subject(:path) { helper.path_for_model(object, slug) }

    let(:slug) { nil }

    context "with an instance of Investigation" do
      let(:object) { create(:allegation) }

      context "with no slug" do
        it "returns /cases/:pretty_id" do
          expect(path).to eq("/cases/#{object.pretty_id}")
        end
      end
    end

    context "with an instance of Business" do
      let(:object) { create(:business) }

      context "with no slug" do
        it "returns /businesses/:id" do
          expect(path).to eq("/businesses/#{object.id}")
        end
      end

      context "with slug" do
        let(:slug) { "documents" }

        it "returns /businesses/:id/:slug" do
          expect(path).to eq("/businesses/#{object.id}/documents")
        end
      end
    end

    context "with an instance of Product" do
      let(:object) { create(:product) }

      context "with no slug" do
        it "returns /products/:id" do
          expect(path).to eq("/products/#{object.id}")
        end
      end
    end
  end

  describe "#associated_documents_path", :with_stubbed_opensearch, :with_stubbed_mailer do
    subject(:path) { helper.associated_documents_path(object) }

    context "with an instance of Business" do
      let(:object) { create(:business) }

      it "returns /businesses/:id/documents" do
        expect(path).to eq("/businesses/#{object.id}/documents")
      end
    end
  end

  describe "#associated_document_path", :with_stubbed_opensearch, :with_stubbed_mailer, :with_stubbed_antivirus do
    subject(:path) { helper.associated_document_path(object, document) }

    let(:document) { object.documents.first }

    context "with an instance of Investigation" do
      let(:object) { create(:allegation, :with_document) }

      it "returns /cases/:pretty_id/documents/:id" do
        expect(path).to eq("/cases/#{object.pretty_id}/documents/#{document.id}")
      end
    end

    context "with an instance of Business" do
      let(:object) { create(:business, :with_document) }

      it "returns /businesses/:id/documents/:id" do
        expect(path).to eq("/businesses/#{object.id}/documents/#{document.id}")
      end
    end
  end

  describe "#associated_document_uploads_path", :with_stubbed_opensearch, :with_stubbed_mailer do
    subject(:path) { helper.associated_document_uploads_path(object) }

    context "with an instance of Product" do
      let(:object) { create(:product) }

      it "returns /products/:id/document_uploads" do
        expect(path).to eq("/products/#{object.id}/document_uploads")
      end
    end
  end

  describe "#associated_document_upload_path", :with_stubbed_opensearch, :with_stubbed_mailer, :with_stubbed_antivirus do
    subject(:path) { helper.associated_document_upload_path(object, document_upload) }

    let(:document_upload) { object.document_uploads.first }

    context "with an instance of Product" do
      let(:object) { create(:product, :with_document_upload) }

      it "returns /products/:product_id/document_uploads/:id" do
        expect(path).to eq("/products/#{object.id}/document_uploads/#{document_upload.id}")
      end
    end
  end

  describe "#attachments_tab_path", :with_stubbed_opensearch, :with_stubbed_mailer, :with_stubbed_antivirus do
    subject(:path) { helper.attachments_tab_path(object, document) }

    let(:document) { object.documents.first }

    context "with an instance of Investigation" do
      let(:object) { create(:allegation, :with_document) }

      context "when no document is given" do
        subject(:path) { helper.attachments_tab_path(object) }

        it "returns /cases/:pretty_id/documents/:id/supporting-information" do
          expect(path).to eq("/cases/#{object.pretty_id}/supporting-information")
        end
      end

      context "when the document is an image" do
        before do
          allow(object.documents.first).to receive(:image?).and_return(true)
        end

        it "returns /cases/:pretty_id/documents/:id/images" do
          expect(path).to eq("/cases/#{object.pretty_id}/images")
        end
      end

      context "when the document is not an image" do
        it "returns /cases/:pretty_id/documents/:id/supporting-information" do
          expect(path).to eq("/cases/#{object.pretty_id}/supporting-information")
        end
      end
    end

    context "with an instance of Business" do
      let(:object) { create(:business, :with_document) }

      it "returns /businesses/:id#attachments" do
        expect(path).to eq("/businesses/#{object.id}#attachments")
      end
    end

    context "with an instance of Product" do
      let(:object) { create(:product, :with_document) }

      it "returns /products/:id#attachments" do
        expect(path).to eq("/products/#{object.id}#attachments")
      end
    end
  end
end
