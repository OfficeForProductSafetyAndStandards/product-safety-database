require "rails_helper"

describe KeycloakService do
  describe ".sync_orgs_and_users_and_teams" do
    before do
      allow(Organisation).to receive(:load_from_keycloak).and_return(true)
      allow(Team).to receive(:load_from_keycloak).and_return(true)
      allow(User).to receive(:load_from_keycloak).and_return(true)
    end

    it "syncs organisations" do
      described_class.sync_orgs_and_users_and_teams
      expect(Organisation).to have_received(:load_from_keycloak)
    end

    it "syncs teams" do
      described_class.sync_orgs_and_users_and_teams
      expect(Team).to have_received(:load_from_keycloak)
    end

    it "syncs users" do
      described_class.sync_orgs_and_users_and_teams
      expect(User).to have_received(:load_from_keycloak)
    end
  end
end
