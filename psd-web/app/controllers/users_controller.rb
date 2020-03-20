class UsersController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :has_accepted_declaration
  skip_before_action :has_viewed_introduction
  skip_before_action :handle_two_factor_authentication

  def complete_registration
    @user = User.find(params[:id])

    return render :signed_in_as_another_user if user_signed_in? && !signed_in_as?(@user)

    # Some users will bookmark the invitation URL received on the email and may re-use
    # this even once their account has been created. Hence redirecting them to the root page.
    return redirect_to(root_path) if signed_in_as?(@user) || @user.has_completed_registration?
    return render(:expired_invitation) if @user.invitation_expired?
    return (render "errors/not_found", status: :not_found) if @user.invitation_token != params[:invitation]

    render :complete_registration
  end

  def sign_out_before_accepting_invitation
    sign_out
    redirect_to complete_registration_user_path(params[:id], invitation: params[:invitation])
  end

  def update
    @user = User.find(params[:id])
    return render("errors/forbidden", status: :forbidden) if params[:invitation] != @user.invitation_token

    @user.assign_attributes(new_user_attributes)
    new_user = NewUser.new(
      id: @user.id,
      email_address: @user.email,
      name: @user.name,
      mobile_number: @user.mobile_number,
      user_encrypted_password: @user.encrypted_password)

    if new_user.valid?(context: :registration_completion)

      # Copy these attributes to the session, as we don’t want to
      # persist them until the user completes 2FA.
      new_user.save

      sign_in :user, @user
      warden.session(:user)[TwoFactorAuthentication::NEED_AUTHENTICATION] = true
      @user.send_new_otp

      redirect_to user_two_factor_authentication_path
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
