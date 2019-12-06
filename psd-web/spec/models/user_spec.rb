require "rails_helper"

RSpec.describe User, with_keycloak_config: true do
  describe ".activated" do
    it "returns only users with activated accounts" do
      create(:user, :inactive)
      activated_user = create(:user, :activated)

      expect(User.activated.to_a).to eq [activated_user]
    end
  end

  describe ".get_team_members" do
    let(:team) { create(:team) }
    let(:user) { create(:user, :activated, teams: [team]) }
    let(:investigation) { create(:allegation) }
    let(:team_members) { described_class.get_team_members(user: user) }

    let!(:another_active_user) { create(:user, :activated, organisation: user.organisation, teams: [team]) }
    let!(:another_inactive_user) { create(:user, :inactive, organisation: user.organisation, teams: [team]) }
    let!(:another_user_with_another_team) { create(:user, :activated, teams: [create(:team)]) }

    it "returns other users on the same team" do
      expect(team_members).to include(another_active_user)
    end

    it "does not return other users on the same team who are not activated" do
      expect(team_members).not_to include(another_inactive_user)
    end

    it "does not return other users on other teams" do
      expect(team_members).not_to include(another_user_with_another_team)
    end
  end

  describe ".get_assignees" do
    let!(:active_user) { create(:user, :activated) }
    let!(:inactive_user) { create(:user, :inactive) }

    it "returns other users" do
      expect(described_class.get_assignees).to include(active_user)
    end

    it "does not return other users who are not activated" do
      expect(described_class.get_assignees).not_to include(inactive_user)
    end

    it "includes associations needed for display_name" do
      assignees = described_class.get_assignees.to_a # to_a forces the query execution and load immediately
      expect(-> {
        assignees.map(&:display_name)
      }).to not_talk_to_db
    end

    context "when a user to except is supplied" do
      it "does not return the excepted user" do
        expect(described_class.get_assignees(except: active_user)).to be_empty
      end
    end
  end

  describe "#roles", with_keycloak_config: true do
    subject(:user) { build(:user) }

    before do
      user.instance_variable_set(:@roles, nil)

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
        expect { user.roles }.to change { Rails.cache.read("user_roles_#{user.id}") }.from(nil).to(keycloak_roles)
      end
    end

    context "when the user's roles are cached" do
      before { Rails.cache.write("user_roles_#{user.id}", cache_roles) }

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

  describe "#display_name" do
    let(:organisation_name) { "test org" }
    let(:other_organisation_name) { "other org" }
    let(:organisation) { create(:organisation, name: organisation_name) }
    let(:other_organisation) { create(:organisation, name: other_organisation_name) }

    let(:team_name) { "test team" }
    let(:other_team_name) { "other team" }
    let(:other_org_team_name) { "other org team" }
    let(:team) { create(:team, name: team_name, organisation: organisation) }
    let(:other_team) { create(:team, name: other_team_name, organisation: organisation) }
    let(:other_organisation_team) { create(:team, name: other_org_team_name, organisation: other_organisation) }

    let(:user_name) { "test user" }
    let(:other_user_name) { "other user" }
    let(:user_organisation) { organisation }
    let(:user_teams) { [] }
    let(:user) { create(:user, name: user_name, organisation: user_organisation, teams: user_teams) }
    let(:other_user) { create(:user, name: other_user_name, organisation: organisation) }

    let(:ignore_visibility_restrictions) { false }

    let(:result) { user.display_name(other_user: other_user, ignore_visibility_restrictions: ignore_visibility_restrictions) }

    context "with other_user" do
      context "when the user is a member of the same organisation" do
        context "when the user has no teams" do
          it "returns their name and organisation name" do
            expect(result).to eq("#{user_name} (#{organisation_name})")
          end
        end

        context "when the user has teams" do
          let(:user_teams) { [team, other_team] }

          it "returns their name and team names" do
            expect(result).to eq("#{user_name} (#{team_name}, #{other_team_name})")
          end
        end
      end

      context "when the user is a member of a different organisation" do
        let(:user_organisation) { other_organisation }

        context "when the user has no teams" do
          it "returns their name and organisation name" do
            expect(result).to eq("#{user_name} (#{other_organisation_name})")
          end
        end

        context "when the user has teams" do
          let(:user_teams) { [other_organisation_team] }

          context "with ignore_visibility_restrictions: false" do
            it "returns their name and organisation name" do
              expect(result).to eq("#{user_name} (#{other_organisation_name})")
            end
          end

          context "with ignore_visibility_restrictions: true" do
            let(:ignore_visibility_restrictions) { true }

            it "returns their name and team names" do
              expect(result).to eq("#{user_name} (#{other_org_team_name})")
            end
          end
        end
      end
    end

    context "with other_user: nil" do
      let(:other_user) { nil }

      it "returns their name and organisation name" do
        expect(result).to eq("#{user_name} (#{organisation_name})")
      end
    end
  end
end
