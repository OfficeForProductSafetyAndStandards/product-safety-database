require "rails_helper"

RSpec.describe "Home page", type: :request do
  context "when not signed in" do
    it "not signed in visits / stays on /" do
      get "/"
      expect(response).to render_template("homepage/show")
    end
  end

  context "when signed in" do
    let(:user) { create(:user, :opss_user, :activated) }

    before { sign_in(user) }

    it "signed in visits / gets redirected to /cases/your-cases" do
      get "/"
      expect(response).to render_template("homepage/authenticated")
    end
  end
end
