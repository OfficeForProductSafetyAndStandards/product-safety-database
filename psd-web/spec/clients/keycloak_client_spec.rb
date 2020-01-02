require "rails_helper"

RSpec.describe KeycloakClient, :with_stubbed_keycloak_config do
  subject { described_class.instance }

  describe "#instance" do
    it "does not retrieve Keycloak config on instantiation" do
      expect(RestClient).not_to receive(:get)
      subject
    end
  end

  describe "#client" do
    it "retrieves Keycloak config lazily" do
      expect(subject.instance_variable_get(:@client)).to be_nil
      expect(RestClient).to receive(:get).with("#{ENV.fetch('KEYCLOAK_AUTH_URL')}/realms/opss/.well-known/openid-configuration")
      subject.client
      expect(subject.instance_variable_get(:@client)).to be(Keycloak::Client)
    end
  end

  describe "#admin" do
    it "sets instance variable lazily" do
      expect(subject.instance_variable_get(:@admin)).to be_nil
      subject.admin
      expect(subject.instance_variable_get(:@admin)).to be(Keycloak::Admin)
    end
  end

  describe "#internal" do
    it "sets instance variable lazily" do
      expect(subject.instance_variable_get(:@internal)).to be_nil
      subject.internal
      expect(subject.instance_variable_get(:@internal)).to be(Keycloak::Internal)
    end
  end

  describe "#reset" do
    subject { described_class.instance }

    it "resets instance variables" do
      described_class.instance.client
      described_class.instance.internal
      described_class.instance.admin
      described_class.instance.reset
      expect(subject.instance_variable_get(:@client)).to be_nil
      expect(subject.instance_variable_get(:@internal)).to be_nil
      expect(subject.instance_variable_get(:@admin)).to be_nil
    end
  end
end
