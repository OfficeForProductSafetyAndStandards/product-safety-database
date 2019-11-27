class HomepageController < ApplicationController
  skip_before_action :authenticate_user!, only: :show
  skip_before_action :authorize_user, only: :show
  skip_before_action :has_accepted_declaration

  def show
    route_user if user_signed_in?
  end

private

  def route_user
    return redirect_to declaration_index_path(redirect_path: params[:request_path]) if !User.current.has_accepted_declaration
    return redirect_to investigations_path if User.current.is_opss?
    return redirect_to introduction_overview_path if !User.current.has_viewed_introduction

    render "non_opss"
  end
end
