# Dont inherit from authentication controller
class SecondaryAuthenticationsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_current_user
  skip_before_action :require_secondary_authentication
  skip_before_action :set_raven_context
  skip_before_action :authorize_user
  skip_before_action :has_accepted_declaration
  skip_before_action :has_viewed_introduction
  skip_before_action :set_cache_headers

  def new
    @secondary_authentication_form = SecondaryAuthenticationForm.new(user_id: session[:secondary_authentication_user_id])
  end

  def create
    params.permit!
    @secondary_authentication_form = SecondaryAuthenticationForm.new(params[:secondary_authentication_form])

    if @secondary_authentication_form.valid?
      set_secondary_authentication_cookie(Time.now.utc.to_i)
      @secondary_authentication_form.secondary_authentication.try_to_verify_user_mobile_number
      session[:secondary_authentication_user_id] = nil
      # redirect to saved path
      if session[:secondary_authentication_redirect_to]
        redirect_to session[:secondary_authentication_redirect_to]
      else
        redirect_to "/"
      end
    else
      if secondary_authentication.otp_expired? && !secondary_authentication.otp_locked?
        secondary_authentication.generate_and_send_code(secondary_authentication.operation)
      end
      @secondary_authentication_form.otp_code = nil
      render :new
    end
  end

private

  def hide_nav?
    true
  end

  def secondary_nav_items
    [text: "Sign out", href: destroy_user_session_path]
  end

  def secondary_authentication
    @secondary_authentication_form.secondary_authentication
  end
end
