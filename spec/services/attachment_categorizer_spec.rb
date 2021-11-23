require "rails_helper"

RSpec.describe AttachmentCategorizer, :with_stubbed_elasticsearch, :with_test_queue_adapter do


  context "#related_investigation" do
    let(:investigation)  { create(:allegation) }

    context "attachment is on a correspondence" do
      let(:correspondence) { create(:correspondence, :with_document, investigation_id: investigation.id) }
      let(:document) { correspondence.documents.first }

      before do
        document.update!(record_type: "Correspondence", record_id: correspondence.id)
      end

      it "returns the investigation" do
        expect(AttachmentCategorizer.new(document.blob).related_investigation).to eq investigation
      end
    end

    context "attachment is on a test result" do
      let(:test_result) { create(:test_result, :with_document, investigation_id: investigation.id) }
      let(:document) { test_result.document }

      before do
        document.update!(record_type: "Test", record_id: test_result.id)
      end

      it "returns the investigation" do
        expect(AttachmentCategorizer.new(document.blob).related_investigation).to eq investigation
      end
    end

    context "attachment is on an investigation" do
      let(:investigation)  { create(:allegation, :with_document) }
      let(:document) { investigation.documents.first }

      before do
        document.update!(record_type: "Investigation", record_id: investigation.id)
      end

      it "returns the investigation" do
        expect(AttachmentCategorizer.new(document.blob).related_investigation).to eq investigation
      end
    end

    context "attachment is on a corrective_action" do
      let(:corrective_action) { create(:corrective_action, :with_document, investigation_id: investigation.id) }
      let(:document) { corrective_action.document }

      before do
        document.update!(record_type: "CorrectiveAction", record_id: corrective_action.id)
      end

      it "returns the investigation" do
        expect(AttachmentCategorizer.new(document.blob).related_investigation).to eq investigation
      end
    end
  end
end
