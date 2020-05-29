require "rails_helper"

RSpec.describe "Adding a comment to a case", type: :request, with_stubbed_mailer: true, with_stubbed_elasticsearch: true do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation) }

  before { sign_in(user) }

  context "with an empty comment" do
    before do
      post investigation_activity_comment_path(investigation),
           params: {
             comment_activity: {
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
      post investigation_activity_comment_path(investigation),
           params: {
             comment_activity: {
               body: "Test"
             }
           }
    end

    it "redirects to the case page" do
      expect(response).to redirect_to(investigation_path(investigation))
    end
  end
end
