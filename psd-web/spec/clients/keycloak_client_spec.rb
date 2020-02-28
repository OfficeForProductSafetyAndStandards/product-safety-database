require "rails_helper"

RSpec.describe KeycloakClient, :with_stubbed_keycloak_config do
  subject(:client) { described_class.instance }

  describe "#instance" do
    it "does not retrieve Keycloak config on instantiation" do
      expect(RestClient).not_to receive(:get)
      client
    end
  end

  describe "#client" do
    before do
      expect(client.instance_variable_get(:@client)).to be_nil
      expect(RestClient).to receive(:get).with("#{ENV.fetch('KEYCLOAK_AUTH_URL')}/realms/opss/.well-known/openid-configuration")
      client.client
    end

    it "retrieves Keycloak config lazily" do
      expect(client.instance_variable_get(:@client)).to be(Keycloak::Client)
    end
  end

  describe "#admin" do
    before do
      expect(client.instance_variable_get(:@admin)).to be_nil
      client.admin
    end

    it "sets instance variable lazily" do
      expect(client.instance_variable_get(:@admin)).to be(Keycloak::Admin)
    end
  end

  describe "#internal" do
    before do
      expect(client.instance_variable_get(:@internal)).to be_nil
      client.internal
    end

    it "sets instance variable lazily" do
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
