module Users
  class PasswordChangedController < ApplicationController
    skip_before_action :has_accepted_declaration,
                       :has_viewed_introduction

    def show; end

    def hide_nav?
      true
    end
  end
end
