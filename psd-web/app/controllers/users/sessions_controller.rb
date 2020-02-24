module Users
  class SessionsController < Devise::SessionsController
    def new
      super { self.resource = resource.decorate }
    end

    def create
      if sign_in_form.invalid?
        resource.errors.merge!(sign_in_form.errors)

        return render :new
      end

      self.resource = warden.authenticate(auth_options)

      if resource
        sign_in(resource_name, resource)
        respond_with resource, location: after_sign_in_path_for(resource)
      else
        self.resource = resource_class.new(sign_in_params).decorate
        resource.errors.add(:email, I18n.t(:wrong_email_or_password, scope: "sign_user_in.email"))
        render :new
      end
    end

  private

    def sign_in_form
      @sign_in_form ||= SignInForm.new(sign_in_params)
    end
  end
end
