require "rails_helper"

RSpec.describe "Login" do
  context "When not logged in" do
    it "redirects to the login page" do
      expect(get(investigations_path))
        .to redirect_to(new_user_session_path)
    end
  end

  context "When not logged in", :with_stubbed_elasticsearch do
    before { sign_in create(:user, :activated, has_viewed_introduction: true) }

    it "does not have a flash messages" do
      expect(get(new_user_session_path))
        .to redirect_to(investigations_path)
      expect(flash).to be_empty
    end
  end
end
