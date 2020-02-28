require "rails_helper"

RSpec.describe ApplicationController do
  context "when not logged in" do
    it "redirects to the login page" do
      expect(get(investigations_path))
        .to redirect_to(root_path)
    end
  end

  context "with an old bookmarked URL" do
    it { expect(get("/sessions/signin")).to redirect_to(root_path) }
  end
end
