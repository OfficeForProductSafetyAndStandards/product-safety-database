module Users
  class TwoFactorAuthenticationController < Devise::TwoFactorAuthenticationController
    skip_before_action :has_accepted_declaration
    skip_before_action :has_viewed_introduction

    def update
      if otp_code_params.empty?
        resource.errors.add(:otp_code, I18n.t(".otp_code.blank"))
        return render :show
      end

      if resource.authenticate_otp(otp_code_params)
        after_two_factor_success_for(resource)
      else
        after_two_factor_fail_for(resource)
      end
    end

  private

    def otp_code_params
      @otp_code_params ||= resource_params.permit(:direct_otp)[:direct_otp]
    end

    def after_two_factor_success_for(resource)
      set_remember_two_factor_cookie(resource)

      warden.session(resource_name)[TwoFactorAuthentication::NEED_AUTHENTICATION] = false
      bypass_sign_in(resource, scope: resource_name)

      resource.update_column(:second_factor_attempts_count, 0)

      redirect_to after_two_factor_success_path_for(resource)
    end

    def after_two_factor_fail_for(resource)
      resource.second_factor_attempts_count += 1
      resource.save

      if resource.max_login_attempts?
        sign_out(resource)
        resource.errors.add(:direct_otp, find_message(:max_login_attempts_reached))
        render :max_login_attempts_reached
      else
        resource.errors.add(:direct_otp, find_message(:attempt_failed))
        render :show
      end
    end
  end
end
