class SyncKeycloakTeamsAndUsersJob < ApplicationJob
  def perform
    KeycloakService.sync_orgs_and_users_and_teams
  end
end
