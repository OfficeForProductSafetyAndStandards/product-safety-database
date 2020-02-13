class SessionsController < Devise::SessionsController
  skip_before_action :has_accepted_declaration
  skip_before_action :has_viewed_introduction

  def new
    # Delete the "You need to be signed in" flash message as we can’t display
    # this on the login page as that happens on an external application (Keycloak).
    # If we don't remove it, it will appear on the page after the user has successfully
    # signed in.
    #
    # TODO: remove this once the sign in page is within the application.
    flash.delete(:notice)
    redirect_to user_openid_connect_omniauth_authorize_path
  end
end
