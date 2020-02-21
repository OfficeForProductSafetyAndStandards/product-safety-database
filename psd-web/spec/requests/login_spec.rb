require "rails_helper"

RSpec.describe "Login" do
  context "When not logged in" do
    it "redirects to the login page" do
      # TODO: update once merged with login flow branch
      expect(get(investigations_path))
        .to redirect_to("/")
    end
  end
end
