require "rails_helper"
require "shared_contexts/oauth_token_exchange"

RSpec.describe Users::ExchangeToken do
  include_context "oauth token exchange"
  let(:cookie_name) { :"keycloak_token_#{ENV["KEYCLOAK_CLIENT_ID"]}" }

  subject do
    described_class.call(
      omniauth_response: omniauth_response,
      keycloak_tokens_store: cookies
    )
  end

  describe ".call", :reset_keycloak_client do
    before do
      expect(KeycloakClient.instance)
        .to receive(:user_signed_in?)
              .with(omniauth_response["credentials"]["access_token"])
              .and_return(:is_user_signed_in)
    end

    context "when the user is signed in" do
      let(:is_user_signed_in) { true }
      before do
        cookies[cookie_name] = { value: omniauth_response.to_json, httponly: true }
      end

      it "does not try to refresh the token" do
        expect(KeycloakClient.instance).to_not receive(:exchange_refresh_token_for_token)
        is_expected.to be_a_success
      end
    end

    context "when the user is not signed it" do
      let(:is_user_signed_in) { false }

      context "when successfully exchanging the token with keycloak" do
        let(:auth_exchange_response) { { access_token: SecureRandom.hex, refresh_token: SecureRandom.hex } }
        before do
          allow(KeycloakClient.instance)
            .to receive(:exchange_refresh_token_for_token)
                  .with(refresh_token)
                  .and_return(auth_exchange_response)
        end
        context "when not previous authentication was saved" do
          it do
            expect { subject.success? }.to change {
              cookies[cookie_name]
            }.from(nil).to(auth_exchange_response)
          end
        end
      end

      context "when failing to exchange the refresh token" do
        before do
          allow(KeycloakClient.instance)
            .to receive(:exchange_refresh_token_for_token)
                  .and_raise(exception_class)
        end

        context "when keycloak is down" do
          let(:exception_class) { Keycloak::KeycloakException }

          it { expect { subject }.to raise_error exception_class }
        end

        context "when anything else goes wrong" do
          let(:exception_class) { StandardError }

          it { is_expected.to be_a_failure }
          it { expect(subject.errors.full_messages).to eq(%w(StandardError)) }
          it do
            expect(Raven).to receive(:capture_exception).with(instance_of(StandardError))
            subject
          end
        end
      end
    end
  end
end
