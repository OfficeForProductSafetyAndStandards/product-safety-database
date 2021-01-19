require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::AddDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
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

  describe "#online_recall_information" do
    context "with online recall information" do
      specify do
        expect(decorated_activity.online_recall_information).to match(online_recall_information)
      end
    end

    context "with no online recall information" do
      let(:online_recall_information)     { nil }
      let(:has_online_recall_information) { CorrectiveAction.has_online_recall_informations["has_online_recall_information_no"] }

      specify do
        expect(decorated_activity.online_recall_information).to eq("Not published online")
      end
    end

    context "when online recall information is not relevant" do
      let(:online_recall_information)     { nil }
      let(:has_online_recall_information) { CorrectiveAction.has_online_recall_informations["has_online_recall_information_not_relevant"] }

      specify do
        expect(decorated_activity.online_recall_information).to eq("Not relevant")
      end
    end
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

      let(:changes) do
        corrective_action.previous_changes.merge("existing_document_id" => [nil, blob.signed_id])
      end

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
