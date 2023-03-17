require "rails_helper"

RSpec.describe "Home page", :with_stubbed_opensearch, type: :request do
  context "when not signed in" do
    it "not signed in visits / stays on /" do
      get "/"
      expect(response).to render_template("homepage/show")
    end
  end

  context "when signed in" do
    before { sign_in(user) }

    context "with a non-opss user" do
      let(:user) { create(:user, :team_admin, :activated) }

      it "signed in visits / gets the non-opss homepage" do
        get "/"
        expect(response).to render_template("homepage/non_opss")
      end
    end

    context "with an opss user" do
      let(:user) { create(:user, :opss_user, :activated) }

      it "signed in visits / gets the opss homepage" do
        get "/"
        expect(response).to render_template("homepage/opss")
      end
    end
  end
end
