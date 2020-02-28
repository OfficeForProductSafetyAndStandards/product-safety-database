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

    context "when the user invitation has expired" do
      let(:user) { create(:user, :invited, account_activated: false, invited_at: 15.days.ago) }

      it "shows a message alerting about the expiration" do
        get complete_registration_user_path(user.id, invitation: user.invitation_token)
        expect(response).to render_template(:expired_invitation)
      end
    end

    context "when the user already created an account with the invitation token" do
      let(:user) { create(:user, :invited, :activated) }

      it "shows a message alerting about the account being already setup" do
        get complete_registration_user_path(user.id, invitation: user.invitation_token)
        expect(response).to redirect_to(root_path)
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
    let(:user) do
      create(:user, :invited, name: nil, encrypted_password: "", mobile_number: nil)
    end

    context "with a matching invitation token and all fields filled in" do
      before do
        patch user_path(user.id),
              params: {
                invitation: user.invitation_token,
                user: {
                  name: "Foo Bar",
                  password: "foobarnoteasyatall1234!",
                  mobile_number: "07235671232"
                }
              }
        user.reload
      end

      it "sets the activated flag on the user" do
        expect(user).to be_account_activated
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end

      it "updates the user model" do
        expect(user.name).to eq("Foo Bar")
        expect(user.mobile_number).to eq("07235671232")
        expect(user.encrypted_password).not_to be_blank
      end
    end

    context "with a mismatched invitation token" do
      before do
        patch user_path(user.id),
              params: {
                invitation: "wrongInvitationToken",
                user: {
                  name: "Foo Bar",
                  password: "foobarnoteasyatall1234!",
                  mobile_number: "07235671232"
                }
              }
        user.reload
      end

      it "renders a 403 forbidden error", with_errors_rendered: true do
        expect(response).to have_http_status :forbidden
        expect(response).to render_template("errors/forbidden")
      end

      it "doesn’t update the user model" do
        expect(user.name).to be_blank
        expect(user.mobile_number).to be_blank
        expect(user.encrypted_password).to be_blank
      end
    end

    context "with missing fields" do
      before do
        patch user_path(user.id),
              params: {
                invitation: user.invitation_token,
                user: {
                  name: "",
                  password: "",
                  mobile_number: ""
                }
              }
      end

      it "re-renders the form" do
        expect(response).to render_template("complete_registration")
      end

      it "doesn’t update the user model" do
        expect(user.name).to be_blank
        expect(user.mobile_number).to be_blank
        expect(user.encrypted_password).to be_blank
      end
    end
  end
end
