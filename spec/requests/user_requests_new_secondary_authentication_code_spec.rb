require "rails_helper"

RSpec.describe "User requests new secondary authentication code", :with_2fa, :with_stubbed_notify, type: :request do
  describe "viewing the form" do
    subject(:request_code) { get new_resend_secondary_authentication_code_path }

    context "with an user session" do
      let(:user) { create(:user, :activated) }

      before do
        sign_in(user)
      end

      it "loads the resend secondary authentication code page", :aggregate_failures do
        request_code

        expect(response).to have_http_status(:ok)
        expect(response).to render_template("secondary_authentications/resend_code/new")
      end
    end

    context "without an user session", :aggregate_failures do
      it "shows an access denied error" do
        request_code

        expect(response).to have_http_status(:forbidden)
        expect(response).to render_template("errors/forbidden")
      end
    end
  end

  describe "submitting the request" do
    context "with an user session" do
      subject(:request_code) { post resend_secondary_authentication_code_path }

      let(:mobile_number) { "07123456789" }
      let(:user) { create(:user, :activated, mobile_number:) }
      let(:expected_phone_number) { "+44 7123 456789" }

      before do
        sign_in(user)
      end

      it "generates a new secondary authentication code for the user" do
        expect {
          request_code
          user.reload
        }.to change(user, :direct_otp)
      end

      it "enqueues an SMS job and sends the code to the user" do
        perform_enqueued_jobs(only: SendSecondaryAuthenticationJob) do
          request_code
        end

        otp = user.reload.direct_otp
        expect(notify_stub).to have_received(:send_sms).with(
          hash_including(phone_number: expected_phone_number, template_id: SendSMS::TEMPLATES[:otp_code], personalisation: { code: otp })
        )
      end

      it "redirects the user to the secondary authentication page" do
        request_code
        expect(response).to redirect_to(new_secondary_authentication_path)
      end
    end

    context "with an user session corresponding to an user who haven't verified their mobile number" do
      subject(:request_code) do
        post resend_secondary_authentication_code_path, params: { user: { mobile_number: } }
      end

      let(:user) { create(:user, mobile_number_verified: false) }

      before do
        sign_in(user)
      end

      context "when a mobile number is not provided" do
        let(:mobile_number) { "" }

        it "shows the submission form" do
          request_code
          expect(response).to render_template("secondary_authentications/resend_code/new")
        end

        it "does not change the user secondary authentication code" do
          expect {
            request_code
            user.reload
          }.not_to change(user, :direct_otp)
        end

        it "does not enqueue an SMS job or send any SMS" do
          expect {
            request_code
          }.not_to have_enqueued_job(SendSecondaryAuthenticationJob)

          expect(notify_stub).not_to have_received(:send_sms)
        end
      end

      context "when a mobile number is provided" do
        let(:mobile_number) { "07123456789" }
        let(:expected_phone_number) { "+44 7123 456789" }

        it "generates a new secondary authentication code for the user" do
          expect {
            request_code
            user.reload
          }.to change(user, :direct_otp)
        end

        it "updates the user mobile number" do
          expect {
            request_code
            user.reload
          }.to change(user, :mobile_number).to(mobile_number)
        end

        it "enqueues an SMS job and sends the code to the user" do
          expect_request_code

          perform_enqueued_jobs(only: SendSecondaryAuthenticationJob)

          # Store the OTP before checking the notify stub
          otp = user.reload.direct_otp

          expect(notify_stub).to have_received(:send_sms).with(
            hash_including(phone_number: expected_phone_number, template_id: SendSMS::TEMPLATES[:otp_code], personalisation: { code: otp })
          )
        end

        it "redirects the user to the secondary authentication page" do
          request_code
          expect(response).to redirect_to(new_secondary_authentication_path)
        end
      end
    end
  end

private

  def expect_request_code
    expect {
      request_code
    }.to have_enqueued_job(SendSecondaryAuthenticationJob).with do |sent_user, sent_code|
      expect(sent_user).to eq(user)
      expect(sent_code).not_to be_nil
    end
  end
end
