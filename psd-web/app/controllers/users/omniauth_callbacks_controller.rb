class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :authenticate_user!
  skip_before_action :set_current_user
  skip_before_action :set_raven_context
  skip_before_action :has_accepted_declaration
  skip_before_action :authorize_user

  def openid_connect
    byebug
  end
end
