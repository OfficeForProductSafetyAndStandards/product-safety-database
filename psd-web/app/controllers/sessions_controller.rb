class SessionsController <  DeviseController
  protect_from_forgery with: :exception
  prepend_before_action :verify_signed_out_user, only: :destroy
  prepend_before_action(only: [:destroy]) { request.env["devise.skip_timeout"] = true }

  def logout
    # ::KeycloakClient.instance.logout(refresh_token)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    redirect_to after_sign_out_path_for(resource_name)
  end

end
