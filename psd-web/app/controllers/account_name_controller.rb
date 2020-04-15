class AccountNameController < ApplicationController
  def show
    @user = current_user
    render "account/name"
  end

  def update
    @user = current_user

    @user.name = params[:user][:name]

    if @user.save(context: :change_name)
      redirect_to account_path
    else
      render "account/name"
    end
  end
end
