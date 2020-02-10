class HomepageController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :authorize_user

  def show
    @show_full_phase_banner = true
  end

private

  def secondary_nav_items
    return super if user_signed_in?

    nil
  end
end
