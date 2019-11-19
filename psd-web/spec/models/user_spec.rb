require "rails_helper"

RSpec.describe User do
  describe ".activated" do
    before do
      @unactivated_user = create(:user)
      @activated_user = create(:user, :activated)
    end

    it "returns only users with activated accounts" do
      expect(User.activated.to_a).to eq [@activated_user]
    end
  end

  describe "#activate!" do
    subject(:user) { build(:user) }

    it "sets the activated flag on the user" do
      expect(user.account_activated?).to be_falsy
      user.activate!
      expect(user.account_activated?).to be_truthy
    end
  end

  describe "#roles", with_keycloak_config: true do
    let(:id) { SecureRandom.uuid }
    subject(:user) { described_class.new(id: id) }

    before do
      allow(ENV).to receive(:fetch).with("KEYCLOAK_AUTH_URL").and_return("test")
      allow(ENV).to receive(:fetch).with("KEYCLOAK_CLIENT_ID").and_return(client_id)
      allow(ENV).to receive(:fetch).with("KEYCLOAK_CLIENT_SECRET").and_return(client_secret)
      allow(KeycloakToken).to receive(:new).and_return(token_stub)
    end

    let(:client_id) { "123" }
    let(:client_secret) { "secret" }
    let(:token_stub) { OpenStruct.new(access_token: "test") }
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
