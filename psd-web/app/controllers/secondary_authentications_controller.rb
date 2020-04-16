# Dont inherit from authentication controller
class SecondaryAuthenticationsController < ActionController::Base
  layout "application"

  def new
    @secondary_authentication = SecondaryAuthentication.find(params[:secondary_authentication_id])
  end

  def create
    params.permit!
    @auth = SecondaryAuthentication.find(params[:secondary_authentication][:id])
    @auth.otp_code = params[:secondary_authentication][:otp_code]
    @auth.authenticate!

    @auth.try_to_verify_user_mobile_number
    set_secondary_authentication_cookie_for(@auth)
    # redirect to saved path
    if session[:secondary_authentication_redirect_to]
      redirect_to session[:secondary_authentication_redirect_to]
    else
      redirect_to '/'
    end
  end

  def set_secondary_authentication_cookie_for(authentication)
    session[:secondary_authentication] << authentication.id
  end

  private
  def nav_items; end
  helper_method :nav_items

  def secondary_nav_items; end
  helper_method :secondary_nav_items
end
