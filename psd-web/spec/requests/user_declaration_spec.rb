require "rails_helper"

describe "User accepting declaration", type: :request, with_keycloak_config: true do
  let(:user) { create(:user) }

  before { sign_in(as_user: user) }

  context "when the user has not already accepted the declaration" do
    before do
      expect(user.has_accepted_declaration).to be_falsy
      expect(user.account_activated).to be_falsy
      post declaration_accept_path, params: { agree: "checked" }
      user.reload
    end

    context "when they accept the declaration" do
      it "sets the user accepted declaration flag" do
        expect(user.has_accepted_declaration).to be_truthy
      end

      it "sets the user account activated flag" do
        expect(user.account_activated).to be_truthy
      end
    end
  end
end
