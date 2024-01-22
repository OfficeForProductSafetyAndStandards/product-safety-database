require "rails_helper"

RSpec.describe "Adding a comment to a case", type: :request, with_stubbed_mailer: true, with_stubbed_opensearch: true do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:notification) { create(:notification, creator: user) }

  before { sign_in(user) }

  context "with an empty comment" do
    before do
      post investigation_activity_comment_path(notification),
           params: {
             comment_form: {
               body: ""
             }
           }
    end

    it "renders the comment form again" do
      expect(response).to render_template(:new)
    end

    it "renders an error" do
      expect(response.body).to include("Enter a comment")
    end
  end

  context "with a valid comment" do
    before do
      post investigation_activity_comment_path(notification),
           params: {
             comment_form: {
               body: "Test"
             }
           }
    end

    it "redirects to the case activities page" do
      expect(response).to redirect_to(investigation_activity_path(notification))
    end

    context "with an notification owned by someone else" do
      let(:notificaiton) { create(:notification) }

      it "redirects to the case activities page" do
        expect(response).to redirect_to(investigation_activity_path(notification))
      end
    end
  end

  context "with a closed notification" do
    let(:notification) { create(:notification, :closed) }

    it "does not allow a comment to be added" do
      post investigation_activity_comment_path(notification), params: { comment_form: { body: "Test" } }
      expect(response).to have_http_status(:forbidden)
    end
  end
end
