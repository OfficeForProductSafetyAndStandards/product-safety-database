require "rails_helper"

RSpec.describe "User submits two factor authentication code", :with_stubbed_notify, :with_stubbed_keycloak_config, type: :request do
  include ActiveSupport::Testing::TimeHelpers

  describe "submitting the form" do
    subject(:submit_2fa) do
      patch user_two_factor_authentication_path,
            params: {
              user: {
                direct_otp: submitted_code
              }
            }
    end

    let(:previous_attempts_count) { 1 }
    let(:user) do
      create(:user, :activated, direct_otp: "12345", second_factor_attempts_count: previous_attempts_count)
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

      shared_examples_for "wrongly formatted two factor code" do |error_message|
        it "does not leave the two factor form page" do
          submit_2fa
          expect(response).to render_template(:show)
        end

        it "displays an error to the user" do
          submit_2fa
          expect(response.body).to include(error_message)
        end

        it "does not increase the user counter for failed two factor attempts" do
          expect {
            submit_2fa
            user.reload
          }.not_to change(user, :second_factor_attempts_count).from(previous_attempts_count)
        end
      end

      context "when the code is too short" do
        let(:submitted_code) { "123" }

        include_examples "wrongly formatted two factor code", "entered enough numbers"
      end

      context "when the code is too long" do
        let(:submitted_code) { "123456789" }

        include_examples "wrongly formatted two factor code", "entered too many numbers"
      end

      context "when the code is empty" do
        let(:submitted_code) { "" }

        include_examples "wrongly formatted two factor code", "Enter the security code"
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

        it "resets the user counter for failed two factor attempts" do
          expect {
            submit_2fa
            user.reload
          }.to change(user, :second_factor_attempts_count).from(previous_attempts_count).to(0)
        end
      end

      context "with a missmatched one time password code" do
        let(:submitted_code) { user.direct_otp.reverse }

        it "does not leave the two factor form page" do
          submit_2fa
          expect(response).to render_template(:show)
        end

        it "displays an error to the user" do
          submit_2fa
          expect(response.body).to include("Incorrect security code")
        end

        it "increases the user counter for failed two factor attempts" do
          expect {
            submit_2fa
            user.reload
          }.to change(user, :second_factor_attempts_count).by(1)
        end
      end

      context "when reaching the maximum number of failing attempts" do
        let(:previous_attempts_count) { User.max_login_attempts - 1 }
        let(:submitted_code) { user.direct_otp.reverse }

        it "increases the user counter for failed two factor attemts" do
          expect {
            submit_2fa
            user.reload
          }.to change(user, :second_factor_attempts_count).from(previous_attempts_count).to(User.max_login_attempts)
        end

        # rubocop:disable RSpec/ExampleLength
        it "records the time when the user gets locked" do
          freeze_time do
            expect {
              submit_2fa
              user.reload
            }.to change(user, :second_factor_attempts_locked_at).from(nil).to(Time.current)
          end
        end
        # rubocop:enable RSpec/ExampleLength

        it "does not leave the two factor form page" do
          submit_2fa
          expect(response).to render_template(:show)
        end

        it "displays a default error to the user" do
          submit_2fa
          expect(response.body).to include("Incorrect security code")
        end
      end

      context "when the user 2fa is locked and submits the correct one time password code" do
        let(:previous_attempts_count) { User.max_login_attempts }
        let(:submitted_code) { user.direct_otp }

        before { user.lock_two_factor! }

        it "does not leave the two factor form page" do
          submit_2fa
          expect(response).to render_template(:show)
        end

        it "displays a default error to the user" do
          submit_2fa
          expect(response.body).to include("Incorrect security code")
        end

        it "does not increase the user counter for failed two factor attempts" do
          expect {
            submit_2fa
            user.reload
          }.not_to change(user, :second_factor_attempts_count).from(previous_attempts_count)
        end
      end

      context "when the user 2fa lock is expired and submits the correct one time password code" do
        let(:previous_attempts_count) { User.max_login_attempts }
        let(:submitted_code) { user.direct_otp }

        before do
          travel_to(Time.current - User::TWO_FACTOR_LOCK_TIME) do
            user.lock_two_factor!
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

        it "resets the user counter for failed two factor attempts" do
          expect {
            submit_2fa
            user.reload
          }.to change(user, :second_factor_attempts_count).from(previous_attempts_count).to(0)
        end

        it "removes the 2fa lock timestamp from the user" do
          expect {
            submit_2fa
            user.reload
          }.to change(user, :second_factor_attempts_locked_at).to(nil)
        end
      end
    end
  end
end
