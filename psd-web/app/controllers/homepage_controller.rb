class HomepageController < ApplicationController
  skip_before_action :authenticate_user!, only: :landing_page
  skip_before_action :authorize_user, only: :landing_page
  skip_before_action :has_accepted_declaration

  def landing_page
    route_user if user_signed_in?
  end

  def show
    route_user
  end

private

  def route_user
    return redirect_to declaration_index_path(redirect_path: params[:request_path]) if !User.current.has_accepted_declaration
    return redirect_to investigations_path if User.current.is_opss?
    return redirect_to introduction_overview_path if !User.current.has_viewed_introduction

    render "non_opss"
  end
end
