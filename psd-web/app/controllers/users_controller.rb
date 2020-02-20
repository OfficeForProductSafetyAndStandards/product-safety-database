class UsersController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :has_accepted_declaration
  skip_before_action :has_viewed_introduction

  def create_account
    @user = User.find(params[:id])

    return render :signed_in_as_another_user if user_signed_in? && current_user != @user

    return redirect_to(root_path) if current_user == @user

    if @user.invitation_expired?
      render(:expired_token)
    elsif @user.account_activated?
      redirect_to("/sign-in")
    elsif @user.invitation_token != params[:invitation]
      render "errors/not_found", status: :not_found
    else
      render :create_account
    end
  end
end
