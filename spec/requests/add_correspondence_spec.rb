require "rails_helper"

RSpec.describe "Adding correspondence to a notification", :with_stubbed_mailer, :with_stubbed_opensearch, type: :request do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:notification) { create(:notification, creator: user) }

  before do
    ChangeNotificationOwner.call!(notification:, owner: user.team, user:)
    sign_in(user)
  end

  context "when not choosing any option" do
    before do
      post investigation_correspondence_index_path(notification), params: { "correspondence_type_form[type]" => nil }
    end

    it "renders the form again" do
      expect(response).to render_template(:new)
    end

    it "renders an error" do
      expect(response.body).to include("Select the type of correspondence you’re adding")
    end
  end

  context  "when choosing a correspondence type" do
    before do
      post investigation_correspondence_index_path(notification), params: { "correspondence_type_form[type]" => type }
    end

    context "when adding an email" do
      let(:type) { "email" }

      it "redirects to new email page" do
        expect(response).to redirect_to(new_investigation_email_path(notification))
      end
    end

    context "when adding a phone call" do
      let(:type) { "phone_call" }

      it "redirects to new phone call page" do
        expect(response).to redirect_to(new_investigation_phone_call_path(notification))
      end
    end
  end
end
