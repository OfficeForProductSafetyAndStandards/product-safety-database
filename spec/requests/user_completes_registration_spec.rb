require "rails_helper"

RSpec.describe "User completes registration", type: :request, with_stubbed_notify: true do
  let(:user) { create(:user, :invited) }

  describe "viewing the form" do
    context "when the url token matches user invitation token" do
      before { get complete_registration_user_path(user.id, invitation: user.invitation_token) }

      it "returns 200 status code" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the complete registration page" do
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

    context "when the user has no invitation token" do
      let(:user) { create(:user, :invited, invitation_token: nil) }

      it "sends visitor to not found page" do
        get complete_registration_user_path(user.id)
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

    context "when the user has set a name, password and mobile number but hasn’t yet verified their mobile number via 2FA" do
      let(:user) { create(:user, invitation_token: "abc123", invited_at: Time.zone.now, account_activated: false, mobile_number_verified: false) }

      before do
        get complete_registration_user_path(user.id, invitation: user.invitation_token)
      end

      it "renders the complete registration page" do
        expect(response).to render_template(:complete_registration)
      end
    end

    context "when the user has already completed their registration" do
      let(:user) { create(:user, invitation_token: "abc123", invited_at: Time.zone.now, account_activated: false) }

      it "redirects to the homepage" do
        get complete_registration_user_path(user.id, invitation: user.invitation_token)
        expect(response).to redirect_to(authenticated_root_path)
      end
    end

    context "when the user is already signed in" do
      let(:user) { create(:user, :invited, account_activated: true) }

      before do
        sign_in user
      end

      it "redirects to the homepage" do
        get complete_registration_user_path(user.id, invitation: user.invitation_token)
        expect(response).to redirect_to(authenticated_root_path)
      end
    end

    context "when a different user is already signed in" do
      let(:other_user) { create(:user, :activated) }
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
                  mobile_number: "07700900000"
                }
              }
        user.reload
      end

      it "does not set the activated flag on the user" do
        expect(user).not_to be_account_activated
      end

      it "does not set the mobile number as verified" do
        expect(user).not_to be_mobile_number_verified
      end

      context "when two factor auth is enabled" do
        it "redirects to the two factor authentication path", :with_2fa do
          follow_redirect!
          expected_path = new_secondary_authentication_path
          expect(response).to redirect_to(expected_path)
        end
      end

      context "when two factor auth is disabled" do
        before do
          allow(Rails.configuration)
            .to receive(:secondary_authentication_enabled)
            .and_return(false)
        end

        it "redirects to the root path" do
          expect(response).to redirect_to(authenticated_root_path)
        end
      end

      it "updates the user’s attributes" do
        expect(user).to have_attributes(name: "Foo Bar", mobile_number: "07700900000")
      end

      it "updates the user’s password" do
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
                  mobile_number: "07700900000"
                }
              }
        user.reload
      end

      it "returns a 403 status code" do
        expect(response).to have_http_status :forbidden
      end

      it "renders the forbidden error page", with_errors_rendered: true do
        expect(response).to render_template("errors/forbidden")
      end

      it "doesn’t update the user name" do
        expect(user.name).to be_blank
      end

      it "doesn’t update the user mobile number" do
        expect(user.mobile_number).to be_blank
      end

      it "doesn’t update the user password" do
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

      it "doesn’t update the user name" do
        expect(user.name).to be_blank
      end

      it "doesn’t update the user mobile number" do
        expect(user.mobile_number).to be_blank
      end

      it "doesn’t update the user password" do
        expect(user.encrypted_password).to be_blank
      end
    end
  end
end
