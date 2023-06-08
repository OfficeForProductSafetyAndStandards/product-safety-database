require "rails_helper"

RSpec.describe "Adding supporting information to a case", type: :request, with_stubbed_mailer: true, with_stubbed_opensearch: true do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, creator: user) }

  before do
    ChangeCaseOwner.call!(investigation:, owner: user.team, user:)
    sign_in(user)
  end

  context "when not choosing any option" do
    before do
      post investigation_supporting_information_index_path(investigation)
    end

    it "renders the form again" do
      expect(response).to render_template(:new)
    end

    it "renders an error" do
      expect(response.body).to include("Select the type of information you’re adding")
    end
  end

  context "when choosing a supporting information type" do
    before do
      post investigation_supporting_information_index_path(investigation),
           params: {
             commit: "Continue",
             type:
           }
    end

    context "when adding a comment" do
      let(:type) { "comment" }

      it "redirects to new comment page" do
        expect(response).to redirect_to(new_investigation_activity_comment_path(investigation))
      end
    end

    context "when adding a corrective action" do
      let(:type) { "corrective_action" }

      it "redirects to new corrective action page" do
        expect(response).to redirect_to(new_investigation_corrective_action_path(investigation))
      end
    end

    context "when adding correspondence" do
      let(:type) { "correspondence" }

      it "redirects to new correspondence page" do
        expect(response).to redirect_to(new_investigation_correspondence_path(investigation))
      end
    end

    context "when adding an image" do
      let(:type) { "image" }

      it "redirects to new document page" do
        expect(response).to redirect_to(new_investigation_document_path(investigation))
      end
    end

    context "when adding generic information" do
      let(:type) { "generic_information" }

      it "redirects to new document page" do
        expect(response).to redirect_to(new_investigation_document_path(investigation))
      end
    end

    context "when adding a test result" do
      let(:type) { "testing_result" }

      it "redirects to new test result page" do
        expect(response).to redirect_to(new_investigation_funding_source_path(investigation))
      end
    end
  end
end
