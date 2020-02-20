require "rails_helper"

RSpec.describe "User completes registration", type: :request, with_stubbed_keycloak_config: true do
  let(:user) { create(:user, :invited) }

  describe "viewing the form" do
    context "when the url token matches user invitation token" do
      it "renders the complete registration page" do
        get complete_registration_user_path(user.id, invitation: user.invitation_token)
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:complete_registration)
      end
    end

    context "when the url points to an inexistent user id", with_errors_rendered: true do
      it "sends visitor to not found page" do
        get complete_registration_user_path(SecureRandom.uuid, invitation: user.invitation_token)
        expect(response).to have_http_status :not_found
      end
    end

    context "when the url token differs from the user invitation token", with_errors_rendered: true do
      it "does not allow the visitor into the complete registration page" do
        get complete_registration_user_path(user.id, invitation: "wrongToken")
        expect(response).to have_http_status :not_found
      end
    end

    context "when the user invitation token has expired" do
      let(:user) { create(:user, :invited, account_activated: false, invited_at: 15.days.ago) }

      it "shows a message alerting about the expiration" do
        get complete_registration_user_path(user.id, invitation: user.invitation_token)
        expect(response).to render_template(:expired_token)
      end
    end

    context "when the user already created an account with the invitation token" do
      let(:user) { create(:user, :invited, :activated) }

      it "shows a message alerting about the account being already setup" do
        get complete_registration_user_path(user.id, invitation: user.invitation_token)
        expect(response).to redirect_to("/sign-in")
      end
    end

    context "when the user is already signed in" do
      let(:user) { create(:user, :invited, :activated) }

      before do
        sign_in user
      end

      it "shows a message alerting about the account being already setup" do
        get complete_registration_user_path(user.id, invitation: user.invitation_token)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when a different user is already signed in" do
      let(:other_user) { create(:user, :invited, :activated) }
      let(:invited_user) { create(:user, :invited) }

      before do
        sign_in other_user
      end

      it "shows a message telling the user they’re already signed in as someone else" do
        get complete_registration_user_path(invited_user.id, invitation: invited_user.invitation_token)
        expect(response).to render_template(:signed_in_as_another_user)
      end
    end
  end

  describe "submitting the form" do
    context "with a matching invitation token and all fields filled in" do
      it "sets the activated flag on the user"

      it "redirects to the root path"

      it "sets the current user"

      it "updates the user model"
    end

    context "with a mismatched invitation token" do
      it "renders a 403 forbidden error"

      it "doesn’t update the user model"
    end

    context "with missing fields" do
      it "re-renders the form"
    end
  end
end
