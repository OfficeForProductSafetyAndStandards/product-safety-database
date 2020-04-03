module Users
  class SessionsController < Devise::SessionsController
    skip_before_action :has_accepted_declaration
    skip_before_action :has_viewed_introduction
    # These methods trigger Warden authentication.
    # We don't want this to happen until we explicitly attempt to authenticate the user.
    skip_before_action :set_current_user, :set_raven_context, :authorize_user, only: :create

    def new
      super { self.resource = resource.decorate }
    end

    # Submission of the sign-in form.
    #
    # This method follows a sequence of steps checking possible errors and edge
    # cases that would impede the user from being signed in.
    # The checks are, in listed order:
    # 1. Are the sumbitted values invalid?
    # 2. Do the credentials correspond to an user that didn't verify its mobile
    #    number through 2FA when completing its user registration?
    # 3. In case of failing authentication. Did the user acount become locked?
    # 4. Were the credentials wrong in the authentication attempt?
    # 5. On successful authentication. Is the user missing its mobile number?
    #
    # When the sign-in submission does not fall under any of these checks,
    # the user will be successfully set and signed in.
    def create
      set_resource_as_new_user_from_params

      # Checks against form attributes validations
      if sign_in_form.invalid?
        resource.errors.merge!(sign_in_form.errors)
        return render :new
      end

      matching_user = User.find_by(email: sign_in_form.email)

      # Stop users from signing in if they’ve not completed 2FA verification
      # of their mobile number during account set up process.
      if user_missing_2fa_mobile_verification?(matching_user)
        sign_out
        add_wrong_credentials_errors
        return render :new
      end

      self.resource = warden.authenticate(auth_options)

      if resource
        handle_authentication_success
      else
        handle_authentication_failure(matching_user)
      end
    end

  private

    def handle_authentication_success
      return redirect_to missing_mobile_number_path if !resource.mobile_number?

      set_current_user
      set_raven_context
      authorize_user
      sign_in(resource_name, resource)
      respond_with resource, location: after_sign_in_path_for(resource)
    end

    def handle_authentication_failure(user)
      return render "account_locked" if user&.reload&.access_locked?

      set_resource_as_new_user_from_params
      add_wrong_credentials_errors
      return render :new
    end


    def sign_in_form
      @sign_in_form ||= SignInForm.new(sign_in_params)
    end

    def add_wrong_credentials_errors
      resource.errors.add(:email, I18n.t(:wrong_email_or_password, scope: "sign_user_in.email"))
      resource.errors.add(:password, nil)
    end

    def user_missing_2fa_mobile_verification?(user)
      Rails.configuration.two_factor_authentication_enabled && user && !user.mobile_number_verified
    end

    def set_resource_as_new_user_from_params
      self.resource = resource_class.new(sign_in_params).decorate
    end
  end
end
