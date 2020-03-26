module Users
  class UnlocksController < Devise::UnlocksController
    def show
      super do |resource|
        if resource.errors.empty?
          cookies.signed[TwoFactorAuthentication::REMEMBER_TFA_COOKIE_NAME] = {
            expires: 60.seconds.ago
          }
        end
      end
    end
  end
end
