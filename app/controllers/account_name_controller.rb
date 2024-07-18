class AccountNameController < ApplicationController
  breadcrumb "account.label", :account_path

  def show
    @user = current_user
    render "account/name"
  end

  def update
    @user = current_user

    @user.name = params.dig(:user, :name)

    if @user.save(context: :change_name)
      render "account/confirmation"
    else
      render "account/name"
    end
  end
end
