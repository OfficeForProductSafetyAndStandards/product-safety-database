module Users
  class TwoFactorAuthenticationController < Devise::TwoFactorAuthenticationController
    skip_before_action :has_accepted_declaration,
                       :has_viewed_introduction

    def show
      suppress_devise_session_alert
    end

    def update
      form = TwoFactorAuthenticationForm.new(otp_code: otp_code_param)

      if form.invalid?
        resource.errors.merge!(form.errors)
        return render :show
      end

      # "resource" is a Devise abstraction over "User" to decouple Devise from
      # how the users are actually called in the application.
      # https://stackoverflow.com/a/48697776/1115009
      if resource.two_factor_locked?
        resource.errors.add(:otp_code, I18n.t(".otp_code.incorrect"))
        return render :show
      end

      if resource.two_factor_authentication_code_expired?
        resource.errors.add(:otp_code, I18n.t(".otp_code.expired"))
        return render :show
      end

      if resource.authenticate_otp(otp_code_param)
        after_two_factor_success_for(resource)
      else
        after_two_factor_fail_for(resource)
      end
    end

    def hide_nav?
      true
    end

    def secondary_nav_items
      [text: "Sign out", href: destroy_user_session_path]
    end

  private

    def otp_code_param
      @otp_code_param ||= resource_params.permit(:otp_code)[:otp_code].strip
    end

    # Suppress unwanted Devise alert.
    # eg: when you try to navigate back to sign-in it alerts about you already being signed in.
    # We only want to show submission errors.
    def suppress_devise_session_alert
      if flash[:alert] == I18n.t(".devise.failure.already_authenticated")
        flash.delete(:alert)
      end
    end

    # BEGIN: Houdini/two_factor_authentication Devise extension overriden
    # methods controllers bellow:
    def after_two_factor_success_for(resource)
      set_remember_two_factor_cookie(resource)

      warden.session(resource_name)[TwoFactorAuthentication::NEED_AUTHENTICATION] = false
      bypass_sign_in(resource, scope: resource_name)

      resource.update(mobile_number_verified: true)

      resource.pass_two_factor_authentication!

      redirect_to after_two_factor_success_path_for(resource)
    end

    def after_two_factor_fail_for(resource)
      resource.fail_two_factor_authentication!
      resource.errors.add(:otp_code, I18n.t(".otp_code.incorrect"))
      render :show
    end

    def prepare_and_validate
      if !resource
        redirect_to :root
      end
    end
    # END of Devise overriding.
  end
end
