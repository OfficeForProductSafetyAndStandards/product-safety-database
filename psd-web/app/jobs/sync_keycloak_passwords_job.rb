class SyncKeycloakPasswordsJob < ApplicationJob
  def perform
    KeycloakConnector.copy_keycloak_credentials
  end
end
