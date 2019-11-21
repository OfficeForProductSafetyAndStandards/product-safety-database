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

  describe ".get_team_members" do
    let(:team) { create(:team) }
    let(:user) { create(:user, :activated, teams: [team]) }
    let(:investigation) { create(:allegation) }
    let(:team_members) { described_class.get_team_members(user: user) }

    before do
      @another_active_user = create(:user, :activated, organisation: user.organisation, teams: [team])
      @another_inactive_user = create(:user, organisation: user.organisation, teams: [team])
      @another_user_with_another_team = create(:user, teams: [create(:team)])
    end

    it "returns other users on the same team" do
      expect(team_members).to include(@another_active_user)
    end

    it "does not return other users on the same team who are not activated" do
      expect(team_members).not_to include(@another_inactive_user)
    end

    it "does not return other users on other teams" do
      expect(team_members).not_to include(@another_user_with_another_team)
    end
  end

  describe ".get_assignees" do
    before do
      @active_user = create(:user, :activated)
      @inactive_user = create(:user)
    end

    it "returns other users" do
      expect(described_class.get_assignees).to include(@active_user)
    end

    it "does not return other users who are not activated" do
      expect(described_class.get_assignees).not_to include(@inactive_user)
    end

    context "when a user to except is supplied" do
      it "does not return the excepted user" do
        expect(described_class.get_assignees(except: @active_user)).to be_empty
      end
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
