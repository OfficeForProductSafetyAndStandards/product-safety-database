require "rails_helper"

RSpec.describe "Login", type: :request do
  context "when not logged in" do
    it "redirects to the login page" do
      expect(get(investigations_path))
        .to redirect_to(new_user_session_path)
    end
  end

  context "with an old bookmarked URL" do
    it { expect(get("/sessions/signin")).to redirect_to(root_path) }
  end

  describe "a user without a mobile number", :with_stubbed_mailer do
    let(:user) { create(:user, :activated, mobile_number: nil) }

    it "displays an error message" do
      stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/sms")
        .and_return(body: {}.to_json, status: 200)

      expect(post(new_user_session_path, params: { user: { email: user.email, password: user.password } }))
        .to redirect_to(missing_mobile_number_path)
    end
  end
end
