require "rails_helper"

RSpec.describe "User account creation", type: :request, with_stubbed_keycloak_config: true do
  let(:user) { create(:user, :invited) }

  context "when the url token matches user invitation token" do
    it "signs in the visitor as the user"

    it "renders the account creation page" do
      get create_account_user_path(user.id, invitation: user.invitation_token)
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:create_account)
    end
  end

  context "when the url points to an inexistent user id" do
    it "sends visitor to not found page" do
      get create_account_user_path(SecureRandom.uuid, invitation: user.invitation_token)
      expect(response).to redirect_to("/404")
      follow_redirect!
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the url token differs from the user invitation token" do
    it "does not allow the visitor into the account creation page" do
      get create_account_user_path(user.id, invitation: "wrongToken")
      expect(response).to redirect_to("/403")
      follow_redirect!
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when the user invitation token has expired" do
    let(:user) { create(:user, :invited, invited_at: 15.days.ago) }

    it "does not sign the user in"

    it "shows a message alerting about the expiration" do
      get create_account_user_path(user.id, invitation: user.invitation_token)
      expect(response).to render_template(:expired_token)
      expect(response.body).to include("has expired")
    end
  end

  context "when the user already created an account with the invitation token" do
    let(:user) { create(:user, :invited, :activated) }

    it "does not sign the user in"

    it "shows a message alerting about the account being already setup" do
      get create_account_user_path(user.id, invitation: user.invitation_token)
      expect(response).to render_template(:already_setup)
      expect(response.body).to include("has already been set up")
    end
  end
end
