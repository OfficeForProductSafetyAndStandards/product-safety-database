class SyncKeycloakPasswordsJob < ApplicationJob
  def perform
    KeycloakCredential.transaction do
      KeycloakCredential.delete_all
      KeycloakConnector.copy_keycloak_credentials
    end
  end
end
