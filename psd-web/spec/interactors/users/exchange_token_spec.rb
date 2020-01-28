require "rails_helper"

RSpec.describe Users::ExchangeToken do
  let(:refresh_token)   { SecureRandom.hex }
  let(:exchanged_token) { SecureRandom.hex }
  let(:omniauth_response) do
    Hashie::Mash.new("credentials" => { "refresh_token" => refresh_token })
  end

  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  subject { described_class.call(omniauth_response: omniauth_response) }

  describe ".call" do
    context "when successfully exchanging the token with keycoak" do
      before do
        allow(KeycloakClient.instance)
          .to receive(:exchange_refresh_token_for_token)
                .with(refresh_token)
                .and_return(exchanged_token)
      end

      it { is_expected.to be_a_success }
      it { expect(subject.access_token).to eq(exchanged_token) }
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
