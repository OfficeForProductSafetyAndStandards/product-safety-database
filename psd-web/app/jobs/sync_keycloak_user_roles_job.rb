class SyncKeycloakUserRolesJob < ApplicationJob
  def perform(user_id)
    User.find(user_id).load_roles_from_keycloak
  end
end
