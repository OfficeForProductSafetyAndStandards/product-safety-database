require "rails_helper"

RSpec.describe "User submits two factor authentication code", :with_stubbed_notify, :with_stubbed_keycloak_config, type: :request do
  include ActiveSupport::Testing::TimeHelpers

  describe "submitting the form" do
    subject(:submit_2fa) do
      patch user_two_factor_authentication_path,
            params: {
              user: {
                otp_code: submitted_code
              }
            }
    end

    let(:previous_attempts_count) { 1 }
    let(:user) do
      create(:user, :activated, direct_otp: "12345",
        mobile_number_verified: false,
        second_factor_attempts_count: previous_attempts_count)
    end

    context "when not signed in prior to submit the 2FA page" do
      let(:submitted_code) { user.direct_otp }

      it "redirects to the main page" do
        submit_2fa
        expect(response).to redirect_to(root_path)
      end

      it "user is not signed in" do
        submit_2fa
        follow_redirect!
        expect(response.body).to include("Sign in to your account")
      end
    end

    context "when successfully completed the sign in step" do
      before { sign_in(user) }

      shared_examples_for "code not accepted" do |error|
        it "does not leave the two factor form page" do
          submit_2fa
          expect(response).to render_template(:show)
        end

        it "displays an error to the user" do
          submit_2fa
          expect(response.body).to include(error)
        end
      end

      context "when the submitted code is invalid" do
        let(:submitted_code) { "" }

        include_examples "code not accepted", "Enter the security code"
      end

      context "with a matching one time password code" do
        let(:submitted_code) { user.direct_otp }

        it "redirects to the main page" do
          submit_2fa
          expect(response).to redirect_to(root_path)
        end

        it "user is signed in" do
          submit_2fa
          follow_redirect!
          expect(response.body).to include("Sign out")
        end

        it "marks the mobile number as verified" do
          submit_2fa
          expect(user.reload.mobile_number_verified).to be true
        end
      end

      context "with a missmatched one time password code" do
        let(:submitted_code) { user.direct_otp.reverse }

        include_examples "code not accepted", "Incorrect security code"
      end

      context "when code expired before being used" do
        let(:submitted_code) { user.direct_otp }

        before do
          user.direct_otp_sent_at = Time.current
          user.save

          expired_code_time = Time.current + User.direct_otp_valid_for + 10.seconds
          travel_to expired_code_time
        end

        after { travel_back }

        include_examples "code not accepted", "The security code has expired"
      end

      context "when reaching the maximum number of failing attempts" do
        let(:previous_attempts_count) { User.max_login_attempts - 1 }
        let(:submitted_code) { user.direct_otp.reverse }

        include_examples "code not accepted", "Incorrect security code"
      end

      context "when the user 2fa is locked and submits the correct one time password code" do
        let(:previous_attempts_count) { User.max_login_attempts }
        let(:submitted_code) { user.direct_otp }

        before { user.update_column(:second_factor_attempts_locked_at, Time.zone.now) }

        include_examples "code not accepted", "Incorrect security code"
      end

      context "when the user 2fa lock is expired and submits the correct one time password code" do
        let(:previous_attempts_count) { User.max_login_attempts }
        let(:submitted_code) { user.direct_otp }

        before do
          travel_to(Time.current - User::TWO_FACTOR_LOCK_TIME) do
            user.update_column(:second_factor_attempts_locked_at, Time.zone.now)
          end
        end

        it "redirects to the main page" do
          submit_2fa
          expect(response).to redirect_to(root_path)
        end

        it "user is signed in" do
          submit_2fa
          follow_redirect!
          expect(response.body).to include("Sign out")
        end
      end
    end
  end
end
