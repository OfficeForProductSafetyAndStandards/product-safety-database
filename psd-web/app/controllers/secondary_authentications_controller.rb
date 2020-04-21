# Dont inherit from authentication controller
class SecondaryAuthenticationsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_current_user
  skip_before_action :cleanup_secondary_authentication
  skip_before_action :require_secondary_authentication
  skip_before_action :set_raven_context
  skip_before_action :authorize_user
  skip_before_action :has_accepted_declaration
  skip_before_action :has_viewed_introduction
  skip_before_action :set_cache_headers

  def new
    @two_factor_authentication_form = TwoFactorAuthenticationForm.new(secondary_authentication_id: params[:secondary_authentication_id])
  end

  def create
    params.permit!
    @two_factor_authentication_form = TwoFactorAuthenticationForm.new(params[:two_factor_authentication_form])

    if @two_factor_authentication_form.valid?
      @two_factor_authentication_form.authenticate!


      set_secondary_authentication_cookie_for(@two_factor_authentication_form.secondary_authentication)
      # redirect to saved path
      if session[:secondary_authentication_redirect_to]
        redirect_to session[:secondary_authentication_redirect_to]
      else
        redirect_to '/'
      end
    else
      @two_factor_authentication_form.otp_code = nil
      render :new
    end
  end

  def set_secondary_authentication_cookie_for(authentication)
    session[:secondary_authentication] << authentication.id
  end

  private
  def nav_items; end
end
