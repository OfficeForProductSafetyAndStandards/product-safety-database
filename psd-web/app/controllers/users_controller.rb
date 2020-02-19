class UsersController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :has_accepted_declaration
  skip_before_action :has_viewed_introduction

  def create_account
    user = User.find(params[:id])
    return redirect_to("/403") unless user.invitation_token == params[:invitation]

    if user.invitation_expired?
      render(:expired_token)
    else
      sign_in(:user, user)
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to("/404")
  end
end
