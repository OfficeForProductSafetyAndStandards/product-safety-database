module Users
  class SessionsController < Devise::SessionsController
    skip_before_action :has_accepted_declaration
    skip_before_action :has_viewed_introduction

    def new
      super { self.resource = resource.decorate }
    end

    def create
      self.resource = resource_class.new(sign_in_params)

      if sign_in_form.invalid?
        resource.errors.merge!(sign_in_form.errors)

        return render :new
      end

      self.resource = warden.authenticate(auth_options)

      if resource
        sign_in(resource_name, resource)
        return respond_with resource, location: after_sign_in_path_for(resource)
      end

      self.resource = resource_class.new(sign_in_params).decorate
      resource.errors.add(:email, I18n.t(:wrong_email_or_password, scope: "sign_user_in.email"))
      resource.errors.add(:password, I18n.t(:wrong_email_or_password, scope: "sign_user_in.email"))
      render :new
    end

  private

    def sign_in_form
      @sign_in_form ||= SignInForm.new(sign_in_params)
    end
  end
end
