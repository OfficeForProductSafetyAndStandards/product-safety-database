module Users
  class SessionsController < Devise::SessionsController

    def new
      super { self.resource = resource.decorate }
    end

    def create
      command = SignUserIn.call(
        resource:     resource_class.new(sign_in_params),
        sign_in_form: sign_in_form,
        warden:       warden,
        auth_options: auth_options
      )

      self.resource = command.resource.decorate

      if command.success?
        sign_in(resource_name, resource)
        respond_with resource, location: after_sign_in_path_for(resource)
      else
        render :new
      end
    end

  private

    def sign_in_form
      @sign_in_form ||= SignInForm.new(sign_in_params)
    end
  end
end
