class IntroductionController < ApplicationController
  skip_before_action :has_viewed_introduction
  def overview; end

  def report_products; end

  def track_investigations; end

  def share_data
    current_user.has_viewed_introduction!
  end

  def skip
    current_user.has_viewed_introduction!
    redirect_to root_path_for(current_user)
  end
end
