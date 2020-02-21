class KeycloakBase < ActiveRecord::Base
  establish_connection :keycloak
  self.abstract_class = true
end
