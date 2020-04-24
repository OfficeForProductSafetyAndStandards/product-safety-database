require "rails_helper"

RSpec.describe "Secondary Authentication submit", :with_stubbed_notify, type: :request do
  let(:attempts) { 0 }
  let(:direct_otp_sent_at) { Time.new.utc }
  let(:secondary_authentication) { SecondaryAuthentication.new(user) }
  let(:submitted_code) { secondary_authentication.direct_otp }
  let(:max_attempts) { SecondaryAuthentication::MAX_ATTEMPTS }

  subject(:submit_2fa) do
    post secondary_authentication_path,
         params: {
         secondary_authentication_form: {
           otp_code: submitted_code,
           user_id: user.id
         }
       }
  end

  let(:previous_attempts_count) { 1 }
  let(:user) do
    create(:user, :activated,
           mobile_number_verified: false,
           direct_otp_sent_at: direct_otp_sent_at,
           second_factor_attempts_count: attempts)
  end

  before do
    secondary_authentication
  end

  context "with successful signup" do
    before { sign_in(user) }

    shared_examples_for "code not accepted" do |*errors|
      it "does not leave the two factor form page" do
        submit_2fa
        expect(response).to render_template(:new)
      end

      it "displays an error to the user" do
        submit_2fa
        errors.each do |error|
          expect(response.body).to include(error)
        end
      end
    end

    context "when code is invalid" do
      let(:submitted_code) { "" }

      include_examples "code not accepted", "Enter the security code"
    end

    context "with correct otp" do
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

    context "with incorrect otp" do
      let(:submitted_code) { secondary_authentication.direct_otp.reverse }

      include_examples "code not accepted", "Incorrect security code"
    end

    context "with expired otp" do
      let(:direct_otp_sent_at) { (SecondaryAuthentication::OTP_EXPIRY_SECONDS * 2).seconds.ago }

      include_examples "code not accepted", "Code expired. New code sent"
    end

    context "with too many attempts" do
      let(:attempts) { max_attempts + 1 }

      include_examples "code not accepted", "Too many attempts. New code sent"
    end
  end
end
