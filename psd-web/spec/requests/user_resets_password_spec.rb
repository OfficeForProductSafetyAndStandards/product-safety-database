require "rails_helper"

RSpec.describe "User resets password", type: :request, with_stubbed_keycloak_config: true do
  describe "viewing the form" do
    context "with a valid reset token" do
      let(:reset_token) { SecureRandom.hex(20) }
      let(:user) { create(:user) }

      before do
        reset_password_digest = Devise.token_generator.digest(user, :reset_password_token, reset_token)

        user.update!(reset_password_token: reset_password_digest, reset_password_sent_at: 1.minute.ago)
      end

      it "displays a reset password form" do
        get(edit_user_password_path(reset_password_token: reset_token))
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("passwords/edit")
      end
    end

    context "with no reset token" do
      it "displays an 'invalid link' error message" do
        get edit_user_password_path
        expect(response).to have_http_status(:not_found)
        expect(response).to render_template("passwords/invalid_link")
      end
    end

    context "with an invalid reset token" do
      let(:user) { create(:user, reset_password_token: SecureRandom.hex(20), reset_password_sent_at: 1.hour.ago) }

      it "displays an 'invalid link' error message" do
        get(edit_user_password_path(reset_password_token: "invalid-token-abc123"))
        expect(response).to have_http_status(:not_found)
        expect(response).to render_template("passwords/invalid_link")
      end
    end

    context "with an expired reset token" do
      let(:reset_token) { SecureRandom.hex(20) }
      let(:user) { create(:user) }

      before do
        reset_password_digest = Devise.token_generator.digest(user, :reset_password_token, reset_token)

        user.update!(reset_password_token: reset_password_digest, reset_password_sent_at: 100.days.ago)
      end

      it "displays an 'expired link' error message" do
        get(edit_user_password_path(reset_password_token: reset_token))
        expect(response).to have_http_status(:gone)
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
      end

      it "redirects to the homepage" do
        patch user_password_path, params: {
          user: {
            reset_password_token: reset_token,
            password: "7rjfy38f74hf937"
          }
        }

        expect(response).to redirect_to(root_path)
      end
    end

    context "with a valid reset token but a missing password" do
      let(:reset_token) { SecureRandom.hex(20) }
      let(:user) { create(:user) }

      before do
        reset_password_digest = Devise.token_generator.digest(user, :reset_password_token, reset_token)

        user.update!(reset_password_token: reset_password_digest, reset_password_sent_at: 1.minute.ago)
      end

      it "re-renders the new password form" do
        patch user_password_path, params: {
          user: {
            reset_password_token: reset_token,
            password: ""
          }
        }

        expect(response).to render_template("passwords/edit")
      end
    end

    context "with a valid reset token but a password that is too short" do
      let(:reset_token) { SecureRandom.hex(20) }
      let(:user) { create(:user) }

      before do
        reset_password_digest = Devise.token_generator.digest(user, :reset_password_token, reset_token)

        user.update!(reset_password_token: reset_password_digest, reset_password_sent_at: 1.minute.ago)
      end

      it "re-renders the new password form" do
        patch user_password_path, params: {
          user: {
            reset_password_token: reset_token,
            password: "abc"
          }
        }

        expect(response).to render_template("passwords/edit")
      end
    end

    context "with a valid reset token but a password that is too common" do
      let(:reset_token) { SecureRandom.hex(20) }
      let(:user) { create(:user) }

      before do
        reset_password_digest = Devise.token_generator.digest(user, :reset_password_token, reset_token)

        user.update!(reset_password_token: reset_password_digest, reset_password_sent_at: 1.minute.ago)
      end

      it "re-renders the new password form" do
        patch user_password_path, params: {
          user: {
            reset_password_token: reset_token,
            password: "Password123"
          }
        }

        expect(response).to render_template("passwords/edit")
      end
    end

    context "with an invalid reset token"
  end
end
