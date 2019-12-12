require "rails_helper"

RSpec.describe "sign in callback route", :with_keycloak_config do
  let(:auth_code) { "test" }
  let(:request_path) { "" }

  before { host! "localhost" }

  subject { get(signin_session_path, params: { code: auth_code, request_path: request_path }) }

  context "when an error occurs exchanging the authorization code for a token with Keycloak" do
    let(:redirect_uri) { keycloak_login_url(redirect_uri: signin_session_url(params: { request_path: request_path })) }

    before { allow(KeycloakClient.instance).to receive(:exchange_code_for_token).with(auth_code, kind_of(String)).and_raise(exception) }

    context "with an unauthorized status code" do
      let(:exception) { RestClient::Unauthorized.new }

      it "redirects to the Keycloak login URL with a generic error message as the alert" do
        expect(subject).to redirect_to(redirect_uri)
        expect(flash[:alert]).to eq("Invalid email or password.")
      end
    end

    context "with any other error" do
      let(:exception) { RestClient::ExceptionWithResponse.new(file_fixture("keycloak_auth_code_error.json").read) }

      it "redirects to the Keycloak login URL with the returned error message as the alert" do
        expect(subject).to redirect_to(redirect_uri)
        expect(flash[:alert]).to eq("Error test")
      end
    end
  end

  context "with a valid authorization code param" do
    before { allow(KeycloakClient.instance).to receive(:exchange_code_for_token).with(auth_code, kind_of(String)) { "token" } }

    context "with blank request_path param" do
      it "redirects to root" do
        expect(subject).to redirect_to(root_path)
      end
    end

    context "with request_path param" do
      let(:request_path) { investigations_path }

      it "redirects to the path in the request_path param" do
        expect(subject).to redirect_to(request_path)
      end
    end
  end
end
