require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::BaseDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  include ActionDispatch::TestProcess::FixtureFile

  subject(:decorated_activity) do
    described_class.decorate(
      AuditActivity::CorrectiveAction::Base.new(
        business: business,
        metadata: { corrective_action_id: corrective_action.id, updates: changes }
      )
    )
  end

  let(:changes)                       { corrective_action.previous_changes }
  let(:business)                      { create(:business) }
  let(:corrective_action)             { create(:corrective_action, business: business, has_online_recall_information: has_online_recall_information, online_recall_information: online_recall_information) }
  let(:online_recall_information)     { Faker::Internet.url(host: "example.com") }
  let(:has_online_recall_information) { CorrectiveAction.has_online_recall_informations["has_online_recall_information_yes"] }

  describe "#trading_name" do
    specify { expect(decorated_activity.trading_name).to eq(business.trading_name) }
  end

  describe "#attachment and #attached_image" do
    context "with an exisiting document id metadata" do
      let(:blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: document,
          filename: Faker::Hipster.word,
          content_type: "text/plain",
          metadata: {}
        )
      end
      let(:changes) { corrective_action.previous_changes.merge(existing_document_file_id: [nil, blob.signed_id]) }

      context "when the document is not an image" do
        let(:document) { fixture_file_upload("corrective_action.txt") }

        it "returns the saved record in the update metadata", :aggregate_failures do
          expect(decorated_activity.attachment).to eq(blob)
          expect(decorated_activity).not_to be_attached_image
        end
      end

      context "when the document is an image" do
        let(:document) { fixture_file_upload("testImage.png") }

        it "returns the saved record in the update metadata", :aggregate_failures do
          expect(decorated_activity.attachment).to eq(blob)
          expect(decorated_activity).to be_attached_image
        end
      end
    end
  end
end
