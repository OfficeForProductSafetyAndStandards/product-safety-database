class UsersController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :has_accepted_declaration
  skip_before_action :has_viewed_introduction

  def complete_registration
    @user = User.find(params[:id])

    return render :signed_in_as_another_user if user_signed_in? && !signed_in_as?(@user)
    return redirect_to(root_path) if signed_in_as?(@user)
    return render(:expired_token) if @user.invitation_expired?
    return redirect_to("/sign-in") if @user.account_activated?
    return (render "errors/not_found", status: :not_found) if @user.invitation_token != params[:invitation]

    render :complete_registration
  end

  def update
    @user = User.find(params[:id])
    return render("errors/forbidden", status: :forbidden) unless params[:invitation] == @user.invitation_token

    @user.assign_attributes(new_user_attributes.merge(account_activated: true))

    if @user.save(context: :registration_completion)
      sign_in :user, @user
      redirect_to root_path
    else
      render :complete_registration
    end
  end

private

  def new_user_attributes
    params.require(:user).permit(:name, :password, :mobile_number)
  end

  def signed_in_as?(user)
    current_user == user
  end
end
