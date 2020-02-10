class SessionsController < Devise::SessionsController
  def destroy
    ::KeycloakClient.instance.logout(refresh_token)
   super
  end
end
