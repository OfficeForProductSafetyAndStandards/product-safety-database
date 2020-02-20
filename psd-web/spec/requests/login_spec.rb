require "rails_helper"

RSpec.describe "Login" do
  context "When not logged in" do
    it "redirects to the login page" do
      expect(get(investigations_path))
        .to redirect_to(root_path)
    end
  end

  context "old bookmarked url" do
    it { expect(get("/sessions/signin")).to redirect_to(root_path) }
  end
end
