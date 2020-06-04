require "rails_helper"

RSpec.describe "Adding supporting information to a case", type: :request, with_stubbed_mailer: true, with_stubbed_elasticsearch: true do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, owner: user.team) }

  before { sign_in(user) }

  context "when not choosing any option" do
    before do
      post investigation_supporting_information_index_path(investigation),
           params: { commit: "Continue" }
    end

    it "renders the form again" do
      expect(response).to render_template(:new)
    end

    it "renders an error" do
      expect(response.body).to include("Supporting information type must not be empty")
    end
  end

  context "when choosing a supporting information type" do
    before do
      post investigation_supporting_information_index_path(investigation),
           params: {
             commit: "Continue",
             supporting_information_type: supporting_information_type
           }
    end

    context "when adding a comment" do
      let(:supporting_information_type) { "comment" }

      it "redirects to new comment page" do
        expect(response).to redirect_to(new_investigation_activity_comment_path(investigation))
      end
    end

    context "when adding a corrective action" do
      let(:supporting_information_type) { "corrective_action" }

      it "redirects to new corrective action page" do
        expect(response).to redirect_to(new_investigation_corrective_action_path(investigation))
      end
    end

    context "when adding correspondence" do
      let(:supporting_information_type) { "correspondence" }

      it "redirects to new correspondence page" do
        expect(response).to redirect_to(new_investigation_correspondence_path(investigation))
      end
    end

    context "when adding an image" do
      let(:supporting_information_type) { "image" }

      it "redirects to new document page" do
        expect(response).to redirect_to(new_investigation_new_path(investigation))
      end
    end

    context "when adding generic information" do
      let(:supporting_information_type) { "generic_information" }

      it "redirects to new document page" do
        expect(response).to redirect_to(new_investigation_new_path(investigation))
      end
    end

    context "when adding a test result" do
      let(:supporting_information_type) { "testing_result" }

      it "redirects to new test result page" do
        expect(response).to redirect_to(new_result_investigation_tests_path(investigation))
      end
    end
  end
end
