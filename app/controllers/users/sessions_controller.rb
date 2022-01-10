module Users
  class SessionsController < Devise::SessionsController
    skip_before_action :has_accepted_declaration
    skip_before_action :has_viewed_introduction
    # These methods trigger Warden authentication.
    # We don't want this to happen until we explicitly attempt to authenticate the user.
    skip_before_action :check_current_user_status, :set_sentry_context, only: :create
    skip_before_action :require_secondary_authentication

    def new
      super { self.resource = resource.decorate }
    end

    def create
      set_resource_as_new_user_from_params

      if sign_in_form.invalid?
        handle_invalid_form(resource)
        return render :new
      end

      matching_user = User.find_by(email: sign_in_form.email)

      if mobile_not_verified?(matching_user)
        handle_mobile_not_verified(resource)
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
      return redirect_to missing_mobile_number_path unless resource.mobile_number?

      check_current_user_status
      set_sentry_context
      sign_in(resource_name, resource)
      respond_with resource, location: after_sign_in_path_for(resource)
    end

    def handle_authentication_failure(user)
      Rails.logger.info "Failed sign in attempt for user: #{user.try(:id)}"

      if user&.reload&.access_locked?
        return render "account_locked" if user.locked_reason == User.locked_reasons[:failed_attempts]

        user.send_unlock_instructions_after_inactivity
        return render "account_locked_inactivity"
      end

      set_resource_as_new_user_from_params
      add_wrong_credentials_errors(resource)
      render :new
    end

    def handle_invalid_form(resource)
      resource.errors.merge!(sign_in_form.errors)
    end

    def handle_mobile_not_verified(resource)
      sign_out
      add_wrong_credentials_errors(resource)
    end

    def sign_in_form
      @sign_in_form ||= SignInForm.new(sign_in_params)
    end

    def add_wrong_credentials_errors(resource)
      return unless resource

      resource.errors.add(:email, I18n.t(:wrong_email_or_password, scope: "sign_user_in.email"))
      resource.errors.add(:password, nil)
    end

    def mobile_not_verified?(user)
      user && !user.mobile_number_verified
    end

    def set_resource_as_new_user_from_params
      self.resource = resource_class.new(sign_in_params).decorate
    end
  end
end
