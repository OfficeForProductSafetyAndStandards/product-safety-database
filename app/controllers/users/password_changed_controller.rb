module Users
  class PasswordChangedController < ApplicationController
    skip_before_action :has_accepted_declaration,
                       :has_viewed_introduction,
                       :require_secondary_authentication

    def show; end

    def hide_nav?
      true
    end
  end
end
