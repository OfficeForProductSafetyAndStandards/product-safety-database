class SessionsController < Devise::SessionsController
  skip_before_action :has_accepted_declaration
  skip_before_action :has_viewed_introduction

  def new
    redirect_to user_openid_connect_omniauth_authorize_path
  end
end
