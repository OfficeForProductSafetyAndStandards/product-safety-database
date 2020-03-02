require "rails_helper"

RSpec.describe KeycloakClient, :with_stubbed_keycloak_config do
  subject(:client) { described_class.instance }

  describe "#instance" do
    before { allow(RestClient).to receive(:get) }

    it "does not retrieve Keycloak config on instantiation" do
      client
      expect(RestClient).not_to have_received(:get)
    end
  end

  describe "#client" do
    let(:response_double) { instance_double("RestClient::Response", code: 200, body: nil) }

    before do
      allow(RestClient).to receive(:get).and_return(response_double)
      client.client
    end

    it "retrieves Keycloak config from the server" do
      expect(RestClient).to have_received(:get).with("#{ENV.fetch('KEYCLOAK_AUTH_URL')}/realms/opss/.well-known/openid-configuration")
    end

    it "sets the client instance variable" do
      expect(client.instance_variable_get(:@client)).to be(Keycloak::Client)
    end
  end

  describe "#admin" do
    it "sets instance variable lazily" do
      client.admin
      expect(client.instance_variable_get(:@admin)).to be(Keycloak::Admin)
    end
  end

  describe "#internal" do
    it "sets instance variable lazily" do
      client.internal
      expect(client.instance_variable_get(:@internal)).to be(Keycloak::Internal)
    end
  end

  describe "#reset" do
    before do
      described_class.instance.client
      described_class.instance.internal
      described_class.instance.admin
      described_class.instance.reset
    end

    it "resets the client instance variable" do
      expect(client.instance_variable_get(:@client)).to be_nil
    end

    it "resets the internal instance variable" do
      expect(client.instance_variable_get(:@internal)).to be_nil
    end

    it "resets the admin instance variable" do
      expect(client.instance_variable_get(:@admin)).to be_nil
    end
  end
end
