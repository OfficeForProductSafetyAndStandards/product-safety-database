class SyncKeycloakDbJob < ApplicationJob
  def perform
    KeycloakConnector.copy_keycloak_data
  end
end
