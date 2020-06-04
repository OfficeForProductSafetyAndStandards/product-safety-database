require "rails_helper"

RSpec.describe "Adding correspondence to a case", type: :request, with_stubbed_mailer: true, with_stubbed_elasticsearch: true do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, owner: user.team) }

  before { sign_in(user) }

  context "when not choosing any option" do
    before do
      get new_investigation_correspondence_path(investigation),
          params: { commit: "Continue" }
    end

    it "renders the form again" do
      expect(response).to render_template(:new)
    end

    it "renders an error" do
      expect(response.body).to include("Correspondence type must not be empty")
    end
  end

  context  "when choosing a correspondence type" do
    before do
      get new_investigation_correspondence_path(investigation),
          params: {
            commit: "Continue",
            correspondence_type: correspondence_type
          }
    end

    context "when adding an email" do
      let(:correspondence_type) { "email" }

      it "redirects to new email page" do
        expect(response).to redirect_to(new_investigation_email_path(investigation))
      end
    end

    context "when adding a meeting" do
      let(:correspondence_type) { "meeting" }

      it "redirects to new meeting page" do
        expect(response).to redirect_to(new_investigation_meeting_path(investigation))
      end
    end

    context "when adding a phone call" do
      let(:correspondence_type) { "phone_call" }

      it "redirects to new phone call page" do
        expect(response).to redirect_to(new_investigation_phone_call_path(investigation))
      end
    end
  end
end
