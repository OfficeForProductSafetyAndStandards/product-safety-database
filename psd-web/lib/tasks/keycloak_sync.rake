namespace :keycloak do
  desc "Sync organisations, users and teams with the Keycloak service"
  task sync: :environment do
    KeycloakService.sync_orgs_and_users_and_teams
  end
end
