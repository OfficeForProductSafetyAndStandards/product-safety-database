class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :has_accepted_declaration
  skip_before_action :has_viewed_introduction
  skip_before_action :authorize_user

  def openid_connect
    if create_user.success?
      sign_in_and_redirect(create_user.user)
      User.current = current_user
    elsif create_user.user.nil?
      redirect_to forbidden_path
    else
      session["devise.openid_connect_data"] = request.env["omniauth.auth"]
      redirect_to user_openid_connect_omniauth_authorize_path
    end
  end

private

  def create_user
    @create_user ||= Users::CreateSession.call(
      user_service: CreateUserFromAuth.new(omniauth_response),
      omniauth_response: omniauth_response
    )
  end

  def omniauth_response
    request.env["omniauth.auth"]
  end
end
