module Users
  class CheckYourEmailController < Devise::PasswordsController
    skip_before_action :require_secondary_authentication

    # This is just a static page
    def show; end
  end
end
