require "rails_helper"

RSpec.describe "HomePage", :with_keycloak_config, :with_elasticsearch do
  context "when not signed in" do
    before do
      allow(KeycloakClient.instance).to receive(:user_signed_in?).and_return(false)
      allow(KeycloakClient.instance).to receive(:login_url).and_return("/login")
    end

    it "not signed in visits / stays on /" do
      visit "/"
      expect(page).to have_content "if you think you should have access"
      expect(page).to_not have_css "a.psd-header__link", text: "BETA"
    end
  end
  context "when signed in" do
    let(:user) { create(:user, :opss_user, :activated) }
    before { sign_in(as_user: user) }

    it "signed in visits / gets redirected to /cases" do
      visit "/"
      expect(page).to have_current_path("/cases")
    end

    it "signed in visits /cases stays on /cases" do
      visit "/cases"
      expect(page).to have_current_path("/cases")
    end
  end
end
