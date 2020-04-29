require "rails_helper"

RSpec.describe UrlHelper do
  describe "#path_for_model", :with_stubbed_elasticsearch do
    subject(:path) { helper.path_for_model(object, slug) }

    let(:slug) { nil }


    context "with an instance of Investigation" do
      let(:object) { create(:allegation, owner: nil) }

      context "with no slug" do
        it "returns /cases/:pretty_id" do
          expect(path).to eq("/cases/#{object.pretty_id}")
        end
      end

      context "with slug" do
        let(:slug) { "attachments" }

        it "returns /cases/:pretty_id/:slug" do
          expect(path).to eq("/cases/#{object.pretty_id}/attachments")
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
  end

  describe "#associated_documents_path", :with_stubbed_elasticsearch do
    subject(:path) { helper.associated_documents_path(object) }

    context "with an instance of Investigation" do
      let(:object) { create(:allegation, owner: nil) }

      it "returns /cases/:pretty_id/attachments" do
        expect(path).to eq("/cases/#{object.pretty_id}/attachments")
      end
    end

    context "with an instance of Business" do
      let(:object) { create(:business) }

      it "returns /businesses/:id/documents" do
        expect(path).to eq("/businesses/#{object.id}/documents")
      end
    end
  end

  describe "#associated_document_path", :with_stubbed_elasticsearch, :with_stubbed_antivirus do
    subject(:path) { helper.associated_document_path(object, document) }

    let(:document) { object.documents.first }


    context "with an instance of Investigation" do
      let(:object) { create(:allegation, :with_document, owner: nil) }

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
end
