class HomepageController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :require_secondary_authentication, if: -> { current_user.nil? }

  def show; end

private

  def secondary_nav_items
    return super if user_signed_in?

    nil
  end
end
