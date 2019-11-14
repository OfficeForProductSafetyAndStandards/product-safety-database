require "rails_helper"

RSpec.describe User, with_keycloak_config: true do
  before do
    allow(Rails.application.config.x.keycloak).to receive(:auth_server_url).and_return("test")
    allow(Rails.application.config.x.keycloak).to receive(:client_id).and_return(client_id)
    allow(Rails.application.config.x.keycloak).to receive(:secret).and_return(client_secret)
    allow(KeycloakToken).to receive(:new).and_return(token_stub)
  end

  let(:client_id) { "123" }
  let(:client_secret) { "secret" }
  let(:token_stub) { OpenStruct.new(access_token: "test") }
  let(:id) { SecureRandom.uuid }

  subject(:user) { described_class.new(id: id) }

  describe "#roles" do
    let(:keycloak_roles) { %w[keycloak_role] }
    let(:cache_roles) { %w[cached_role] }
    let(:instance_roles) { %w[instance_role] }

    let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

    before do
      allow(Rails).to receive(:cache).and_return(memory_store)
      Rails.cache.clear
    end

    context "when the user's roles are not cached" do
      before { expect(KeycloakClient.instance).to receive(:get_user_roles).and_return(keycloak_roles) }

      it "returns the roles from Keycloak" do
        expect(user.roles).to eq(keycloak_roles)
      end

      it "caches the roles" do
        expect { user.roles }.to change { Rails.cache.read("user_roles_#{id}") }.from(nil).to(keycloak_roles)
      end
    end

    context "when the user's roles are cached" do
      before { Rails.cache.write("user_roles_#{id}", cache_roles) }

      it "returns the cached roles" do
        expect(user.roles).to eq(cache_roles)
      end

      it "does not query Keycloak" do
        expect(KeycloakClient.instance).not_to receive(:get_user_roles)
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
        expect(KeycloakClient.instance).not_to receive(:get_user_roles)
        user.roles
      end
    end
  end
end
