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
    return render("errors/forbidden", status: :forbidden) unless session[:secondary_authentication_user_id]

    @secondary_authentication_form = SecondaryAuthenticationForm.new(user_id: session[:secondary_authentication_user_id])
  end

  def create
    if secondary_authentication_form.valid?
      set_secondary_authentication_cookie(Time.zone.now.utc.to_i)
      secondary_authentication_form.try_to_verify_user_mobile_number
      redirect_to_saved_path
    else
      try_to_resend_code
      secondary_authentication_form.otp_code = nil
      render :new
    end
  end

private

  def hide_nav?
    if secondary_authentication&.operation == SecondaryAuthentication::INVITE_USER
      super
    else
      true
    end
  end

  def secondary_nav_items
    if secondary_authentication&.operation == SecondaryAuthentication::INVITE_USER
      super
    else
      [text: "Sign out", href: destroy_user_session_path]
    end
  end

  def secondary_authentication
    @secondary_authentication_form&.secondary_authentication
  end

  def redirect_to_saved_path
    session[:secondary_authentication_user_id] = nil
    if session[:secondary_authentication_redirect_to]
      redirect_to session.delete(:secondary_authentication_redirect_to)
    else
      redirect_to root_path_for(current_user)
    end
  end

  def try_to_resend_code
    if secondary_authentication.otp_expired? && !secondary_authentication.otp_locked?
      secondary_authentication.generate_and_send_code(secondary_authentication.operation)
    end
  end

  def secondary_authentication_form
    @secondary_authentication_form ||= SecondaryAuthenticationForm.new(secondary_authentication_params)
  end

  def secondary_authentication_params
    params.require(:secondary_authentication_form).permit(:otp_code, :user_id)
  end
end
