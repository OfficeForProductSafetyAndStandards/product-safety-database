require "rails_helper"

RSpec.describe "HomePage", :with_elasticsearch do
  context "when not signed in" do
    before do
      allow(KeycloakClient.instance).to receive(:user_signed_in?).and_return(false)
      allow(KeycloakClient.instance).to receive(:login_url).and_return("/login")
    end

    it "not signed in visits / stays on /" do
      get "/"
      expect(response).to render_template("homepage/show")
    end
  end

  context "when signed in" do
    let(:user) { create(:user, :opss_user, :activated) }
    before { sign_in(as_user: user) }

    it "signed in visits / gets redirected to /cases" do
      get "/"
      expect(response).to redirect_to("/cases")
    end

    it "signed in visits /cases stays on /cases" do
      get "/"
      expect(response).to redirect_to("/cases")
    end
  end
end
