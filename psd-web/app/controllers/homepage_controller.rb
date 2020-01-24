class HomepageController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :authorize_user

  def show
    route_user if user_signed_in?
    @show_full_phase_banner = true
  end

private

  def route_user
    return redirect_to declaration_index_path(redirect_path: params[:request_path]) if !current_user.has_accepted_declaration
    return redirect_to investigations_path if current_user.is_opss?
    return redirect_to introduction_overview_path if !current_user.has_viewed_introduction

    render "non_opss"
  end

  def secondary_nav_items
    return super if user_signed_in?

    nil
  end
end
