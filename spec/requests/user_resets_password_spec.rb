RSpec.describe "User resets password", type: :request, with_stubbed_notify: true, with_2fa: true do
  describe "viewing the form" do
    context "with a valid reset token" do
      let(:reset_token) { SecureRandom.hex(20) }
      let(:user) { create(:user) }

      before do
        reset_password_digest = Devise.token_generator.digest(user, :reset_password_token, reset_token)
        user.update!(reset_password_token: reset_password_digest, reset_password_sent_at: 1.minute.ago)
      end

      it "redirects the user to the two factor authentication page" do
        get(edit_user_password_path(reset_password_token: reset_token))

        expected_path = new_secondary_authentication_path
        expect(response).to redirect_to(expected_path)
      end
    end

    context "with no reset token" do
      before { get edit_user_password_path }

      it "returns a 404 status code" do
        expect(response).to have_http_status(:not_found)
      end

      it "displays an 'invalid link' error message" do
        expect(response).to render_template("passwords/invalid_link")
      end
    end

    context "with an invalid reset token" do
      let(:user) { create(:user, reset_password_token: SecureRandom.hex(20), reset_password_sent_at: 1.hour.ago) }

      before do
        get(edit_user_password_path(reset_password_token: "invalid-token-abc123"))
      end

      it "returns a 404 status code" do
        expect(response).to have_http_status(:not_found)
      end

      it "displays an 'invalid link' error message" do
        expect(response).to render_template("passwords/invalid_link")
      end
    end

    context "with an expired reset token" do
      let(:reset_token) { SecureRandom.hex(20) }
      let(:user) { create(:user) }

      before do
        reset_password_digest = Devise.token_generator.digest(user, :reset_password_token, reset_token)

        user.update!(reset_password_token: reset_password_digest, reset_password_sent_at: 100.days.ago)

        get(edit_user_password_path(reset_password_token: reset_token))
      end

      it "returns a 410 Gone status code" do
        expect(response).to have_http_status(:gone)
      end

      it "displays an 'expired link' error message" do
        expect(response).to render_template("passwords/expired")
      end
    end
  end

  describe "submitting a new password" do
    context "with a valid reset token and new password" do
      let(:reset_token) { SecureRandom.hex(20) }
      let(:user) { create(:user) }

      before do
        reset_password_digest = Devise.token_generator.digest(user, :reset_password_token, reset_token)

        user.update!(reset_password_token: reset_password_digest, reset_password_sent_at: 1.minute.ago)

        patch user_password_path,
              params: {
                user: {
                  reset_password_token: reset_token,
                  password: "7rjfy38f74hf937"
                }
              }
      end

      it "redirects to the password changed page" do
        expect(response).to redirect_to(password_changed_path)
      end
    end

    context "with a valid reset token but a missing password" do
      let(:reset_token) { SecureRandom.hex(20) }
      let(:user) { create(:user) }

      before do
        reset_password_digest = Devise.token_generator.digest(user, :reset_password_token, reset_token)

        user.update!(reset_password_token: reset_password_digest, reset_password_sent_at: 1.minute.ago)

        patch user_password_path,
              params: {
                user: {
                  reset_password_token: reset_token,
                  password: ""
                }
              }
      end

      it "re-renders the new password form" do
        expect(response).to render_template("passwords/edit")
      end
    end

    context "with a valid reset token but a password that is too short" do
      let(:reset_token) { SecureRandom.hex(20) }
      let(:user) { create(:user) }

      before do
        reset_password_digest = Devise.token_generator.digest(user, :reset_password_token, reset_token)

        user.update!(reset_password_token: reset_password_digest, reset_password_sent_at: 1.minute.ago)

        patch user_password_path,
              params: {
                user: {
                  reset_password_token: reset_token,
                  password: "abc"
                }
              }
      end

      it "re-renders the new password form" do
        expect(response).to render_template("passwords/edit")
      end
    end

    context "with a valid reset token but a password that is too common" do
      let(:reset_token) { SecureRandom.hex(20) }
      let(:user) { create(:user) }

      before do
        reset_password_digest = Devise.token_generator.digest(user, :reset_password_token, reset_token)

        user.update!(reset_password_token: reset_password_digest, reset_password_sent_at: 1.minute.ago)

        patch user_password_path,
              params: {
                user: {
                  reset_password_token: reset_token,
                  password: "Password123"
                }
              }
      end

      it "re-renders the new password form" do
        expect(response).to render_template("passwords/edit")
      end
    end

    context "with an invalid reset token"
  end
end
