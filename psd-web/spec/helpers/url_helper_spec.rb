require "rails_helper"

RSpec.describe UrlHelper do
  describe "#path_for_model", :with_stubbed_elasticsearch do
    let(:slug) { nil }

    subject { helper.path_for_model(object, slug) }

    context "with an instance of Investigation" do
      let(:object) { create(:allegation, assignee: nil) }

      context "with no slug" do
        it "returns /cases/:pretty_id" do
          expect(subject).to eq("/cases/#{object.pretty_id}")
        end
      end

      context "with slug" do
        let(:slug) { "attachments" }

        it "returns /cases/:pretty_id/:slug" do
          expect(subject).to eq("/cases/#{object.pretty_id}/attachments")
        end
      end
    end

    context "with an instance of Business" do
      let(:object) { create(:business) }

      context "with no slug" do
        it "returns /businesses/:id" do
          expect(subject).to eq("/businesses/#{object.id}")
        end
      end

      context "with slug" do
        let(:slug) { "documents" }

        it "returns /businesses/:id/:slug" do
          expect(subject).to eq("/businesses/#{object.id}/documents")
        end
      end
    end
  end

  describe "#associated_documents_path", :with_stubbed_elasticsearch do
    subject { helper.associated_documents_path(object) }

    context "with an instance of Investigation" do
      let(:object) { create(:allegation, assignee: nil) }

      it "returns /cases/:pretty_id/attachments" do
        expect(subject).to eq("/cases/#{object.pretty_id}/attachments")
      end
    end

    context "with an instance of Business" do
      let(:object) { create(:business) }

      it "returns /businesses/:id/documents" do
        expect(subject).to eq("/businesses/#{object.id}/documents")
      end
    end
  end

  describe "#associated_document_path", :with_stubbed_elasticsearch, :with_stubbed_antivirus do
    let(:document) { object.documents.first }

    subject { helper.associated_document_path(object, document) }

    context "with an instance of Investigation" do
      let(:object) { create(:allegation, :with_document, assignee: nil) }

      it "returns /cases/:pretty_id/documents/:id" do
        expect(subject).to eq("/cases/#{object.pretty_id}/documents/#{document.id}")
      end
    end

    context "with an instance of Business" do
      let(:object) { create(:business, :with_document) }

      it "returns /businesses/:id/documents/:id" do
        expect(subject).to eq("/businesses/#{object.id}/documents/#{document.id}")
      end
    end
  end
end
