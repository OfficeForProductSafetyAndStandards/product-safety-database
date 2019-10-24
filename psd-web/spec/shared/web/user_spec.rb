require 'spec_helper'

RSpec.describe Shared::Web::User do
  before do
    allow(ENV).to receive(:fetch).with('KEYCLOAK_CLIENT_ID').and_return(client_id)
    allow(ENV).to receive(:fetch).with('KEYCLOAK_CLIENT_SECRET').and_return(client_secret)
    allow(Keycloak::Internal).to receive(:token).and_return(token_stub)
  end

  let(:client_id) { "123" }
  let(:client_secret) { "secret" }
  let(:token_stub) { OpenStruct.new(access_token: "test") }
  let(:id) { 123 }

  subject(:user) { described_class.new(id: id) }

  describe "#roles" do
    let(:keycloak_roles) { ["keycloak_role"] }
    let(:cache_roles) { ["cached_role"] }
    let(:instance_roles) { ["instance_role"] }

    let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

    before do
      allow(Rails).to receive(:cache).and_return(memory_store)
      Rails.cache.clear
    end

    context "when the user's roles are not cached" do
      before { expect(Shared::Web::KeycloakClient.instance).to receive(:get_user_roles).and_return(keycloak_roles) }

      it "returns the roles from Keycloak" do
        expect(user.roles).to eq(keycloak_roles)
      end

      it "caches the roles" do
        user.roles
        expect(Rails.cache.read("user_roles_#{id}")).to eq(keycloak_roles)
      end
    end

    context "when the user's roles are cached" do
      before { Rails.cache.write("user_roles_#{id}", cache_roles) }

      it "returns the cached roles" do
        expect(user.roles).to eq(cache_roles)
      end

      it "does not query Keycloak" do
        expect(Shared::Web::KeycloakClient.instance).not_to receive(:get_user_roles)
        user.roles
      end
    end

    context "when the roles have already been instantiated" do
      before { user.roles = instance_roles }

      it "returns the already instantiated roles" do
        expect(user.roles).to eq(instance_roles)
      end

      it "does not query the cache" do
        expect(Rails).not_to receive(:cache)
        user.roles
      end

      it "does not query Keycloak" do
        expect(Shared::Web::KeycloakClient.instance).not_to receive(:get_user_roles)
        user.roles
      end
    end
  end
end
