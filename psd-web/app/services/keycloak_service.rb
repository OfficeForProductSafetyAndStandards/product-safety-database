class KeycloakService
  def self.sync_orgs_and_users_and_teams
    Organisation.load_from_keycloak
    Team.load_from_keycloak
    User.load_from_keycloak
  end
end
