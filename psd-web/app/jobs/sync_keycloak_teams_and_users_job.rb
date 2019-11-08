class SyncKeycloakTeamsAndUsersJob < ApplicationJob
  def perform
    Organisation.load_from_keycloak
    Team.load_from_keycloak
    User.load_from_keycloak
  end
end
