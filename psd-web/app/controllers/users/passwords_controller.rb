class Users::PasswordsController < Devise::PasswordsController

  def create

  end

  private

  def after_sending_reset_password_instructions_path_for(resource_name)

  end
end
