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
    context "without an user session" do
      it "shows an access denied error", :aggregate_failures do
        post resend_secondary_authentication_code_path

        expect(response).to have_http_status(:forbidden)
        expect(response).to render_template("errors/forbidden")
      end
    end

    context "with an user session" do
      subject(:request_code) { post resend_secondary_authentication_code_path }

      let(:user) { create(:user, :activated) }

      before do
        sign_in(user)
      end

      it "generates a new secondary authentication code for the user" do
        expect {
          request_code
          user.reload
        }.to change(user, :direct_otp)
      end

      it "sends the code to the user by sms" do
        request_code

        perform_enqueued_jobs

        expect(notify_stub).to have_received(:send_sms).with(
          hash_including(phone_number: user.mobile_number, personalisation: { code: user.reload.direct_otp })
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

        it "does not send any sms to the user" do
          request_code

          expect(notify_stub).not_to have_received(:send_sms)
        end
      end

      context "when a mobile number is provided" do
        let(:mobile_number) { "07123456789" }

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

        it "sends the code to the user by sms" do
          request_code

          perform_enqueued_jobs

          expect(notify_stub).to have_received(:send_sms).with(
            hash_including(phone_number: user.mobile_number, personalisation: { code: user.reload.direct_otp })
          )
        end

        it "redirects the user to the secondary authentication page" do
          request_code

          expect(response).to redirect_to(new_secondary_authentication_path)
        end
      end
    end
  end
end
