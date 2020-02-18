module Users
  class SessionsController < Devise::SessionsController

    def create
      if user_session_form.invalid?
        self.resource = resource_class.new(create_session_params)
        return render :new
      end

      self.resource = warden.authenticate(auth_options)
      sign_in(resource_name, resource)
      respond_with resource, location: after_sign_in_path_for(resource)
    end

  private

    def user_session_form
      @sign_in_validator ||= SignUserIn.new(create_session_params)
    end

    def create_session_params
      params.require(:user).permit(:email, :password)
    end
  end
end
